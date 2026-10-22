import 'dart:convert';

/// Backup and restore for planner notes.
///
/// Pure Dart: no Flutter, no file system, no platform imports. Everything here
/// is a function over maps and strings, so it is fully unit-testable and the
/// platform edge in `backup_io.dart` stays trivial.
///
/// ## The two things that must not be got wrong
///
/// 1. **Values are typed.** The store keeps text and flags in separate
///    SharedPreferences buckets, so the file has to carry the distinction.
///    JSON does that for free: `"key": "text"` versus `"key": true`. On import
///    the type comes back from the JSON value's runtime type.
///
/// 2. **Empty text means "no note".** `Store.setText(key, '')` deletes the
///    key rather than storing an empty string. So an empty value in a file
///    means the note was never there, and applying it would delete a note the
///    file did not intend to touch. Empty values are therefore **skipped**, not
///    written. A consequence: a backup cannot express "delete this note" —
///    deletion is done in the UI.

/// Version of the on-disk format. Bump when the shape changes incompatibly.
const int backupFormatVersion = 1;

/// Key prefix reserved for the app's own backup machinery inside the store.
///
/// Keys under this prefix are never part of a note export — otherwise an
/// export would contain the snapshot of an earlier export.
const String kBackupKeyPrefix = 'backup:';

/// Where the pre-import snapshot lives.
const String kBackupSnapshotKey = '${kBackupKeyPrefix}snapshot';

/// Key prefix reserved for UI state (which notices have been dismissed).
///
/// Also excluded from exports and rejected on import. Otherwise a backup
/// carries the flag, and importing it would re-show — or re-dismiss — a notice
/// on a device where the user never made that choice.
const String kUiKeyPrefix = 'ui:';

/// A parsed backup file.
class Backup {
  const Backup({
    required this.formatVersion,
    required this.createdAt,
    required this.notes,
  });

  final int formatVersion;
  final DateTime createdAt;

  /// Flat key → `String` | `bool`. Never contains any other type.
  final Map<String, Object> notes;
}

/// What importing a file would do to the notes already on the device.
class BackupDiff {
  const BackupDiff({
    required this.added,
    required this.overwritten,
    required this.unchanged,
  });

  /// Keys in the file the device does not have.
  final int added;

  /// Keys both have, where the values differ — the file would win.
  final int overwritten;

  /// Keys both have with identical values. Nothing happens to these.
  final int unchanged;

  int get total => added + overwritten + unchanged;

  /// True when applying the file would change nothing at all.
  bool get isNoOp => added == 0 && overwritten == 0;

  /// One-line summary for the pre-import confirmation, e.g.
  /// "12 to add · 3 to replace · 2 unchanged".
  String get summary => '$added to add · $overwritten to replace · $unchanged unchanged';
}

/// Thrown when a file cannot be parsed as a backup.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatException: $message';
}

/// Serialise [notes] to a pretty-printed JSON string.
///
/// Skips values that are not `String` or `bool`, and skips empty strings, so
/// the output only ever contains what a restore would actually want to write.
String encodeBackup(Map<String, Object> notes, {DateTime? createdAt}) {
  final clean = <String, Object>{};
  for (final entry in notes.entries) {
    final v = entry.value;
    if (v is String) {
      if (v.isNotEmpty) clean[entry.key] = v;
    } else if (v is bool) {
      clean[entry.key] = v;
    }
  }
  final out = <String, Object>{
    'formatVersion': backupFormatVersion,
    'app': 'asu_planner',
    'planYear': 2027,
    'createdAt': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
    'notes': clean,
  };
  return const JsonEncoder.withIndent('  ').convert(out);
}

/// Parse a backup. Throws [BackupFormatException] on anything malformed.
///
/// Validation happens entirely before this returns, so a caller can never see
/// a half-valid [Backup] and a corrupt file is rejected whole.
Backup decodeBackup(String json) {
  Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException catch (e) {
    throw BackupFormatException('Not valid JSON: ${e.message}');
  }
  if (root is! Map<String, dynamic>) {
    throw const BackupFormatException('Expected a JSON object at the top level.');
  }

  final version = root['formatVersion'];
  if (version is! int) {
    throw const BackupFormatException('Missing or non-integer "formatVersion".');
  }
  if (version != backupFormatVersion) {
    throw BackupFormatException(
        'Unsupported formatVersion $version. This app reads version $backupFormatVersion.');
  }

  final raw = root['notes'];
  if (raw is! Map<String, dynamic>) {
    throw const BackupFormatException('Missing or invalid "notes" object.');
  }

  final notes = <String, Object>{};
  for (final entry in raw.entries) {
    if (entry.key.startsWith(kBackupKeyPrefix) ||
        entry.key.startsWith(kUiKeyPrefix)) {
      throw BackupFormatException(
          'Key "${entry.key}" is reserved for app state and cannot be imported.');
    }
    final v = entry.value;
    if (v is String) {
      // Empty means "no note" — see the class doc. Never emit, never apply.
      if (v.isNotEmpty) notes[entry.key] = v;
    } else if (v is bool) {
      notes[entry.key] = v;
    } else {
      throw BackupFormatException(
          'Key "${entry.key}" has a value of type ${v.runtimeType}. Only text and on/off flags are supported.');
    }
  }

  final createdAt = root['createdAt'];
  return Backup(
    formatVersion: version,
    createdAt: createdAt is String ? (DateTime.tryParse(createdAt) ?? DateTime.now()) : DateTime.now(),
    notes: notes,
  );
}

/// Merge [incoming] into [existing]: the backup wins, the device keeps
/// whatever the backup does not mention.
Map<String, Object> mergeNotes(
    Map<String, Object> existing, Map<String, Object> incoming) {
  final out = Map<String, Object>.from(existing);
  out.addAll(incoming);
  return out;
}

/// Classify what [incoming] would do to [existing], without doing it.
BackupDiff diffNotes(Map<String, Object> existing, Map<String, Object> incoming) {
  var added = 0, overwritten = 0, unchanged = 0;
  for (final entry in incoming.entries) {
    if (!existing.containsKey(entry.key)) {
      added++;
    } else if (existing[entry.key] == entry.value) {
      unchanged++;
    } else {
      overwritten++;
    }
  }
  return BackupDiff(added: added, overwritten: overwritten, unchanged: unchanged);
}

/// Suggested filename for an export, e.g. `asu-planner-2027-2026-10-16.json`.
String backupFileName({DateTime? when}) {
  final d = when ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${d.year}-${two(d.month)}-${two(d.day)}';
  return 'asu-planner-2027-$date.json';
}

/// Suggested filename for the pre-import safety snapshot.
String snapshotFileName({DateTime? when}) {
  final d = when ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${d.year}-${two(d.month)}-${two(d.day)}';
  return 'asu-planner-PRE-IMPORT-$date.json';
}
