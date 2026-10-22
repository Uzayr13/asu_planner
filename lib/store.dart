import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup/backup.dart';

/// Tiny key/value store for all user-entered text and toggles.
///
/// Keys, exactly as the pages construct them (see `dateKey` in
/// `data/calendar_math.dart` for the zero-padded YYYY-MM-DD form):
///
///   day:<date>            day note, shared by month/week/day views
///   dv:<date>:p0..2       day priorities (text)
///   dvf:<date>:0..2       day priority checkboxes (bool)
///   dv:<date>:h6..h21     schedule slots (text)
///   dv:<date>:word        one Arabic word today (text)
///   habit:<monday>:0..6   habit dots (bool)
///   wk:<week>:p0..2       week priorities (text)
///   prio:<week>:0..2      week priority checkboxes (bool)
///   note:<page>:<line>    notes pages, page 1..2, line 0..19
///   word:<row>:<col>      vocabulary table, 13 rows x 4 cols
///
/// Text and flags are stored in separate SharedPreferences buckets — reading
/// a flag key with `getString` throws. Anything that serialises the store must
/// carry that distinction along; see `lib/backup/backup.dart`.
class Store extends ChangeNotifier {
  Store._(this._p);
  final SharedPreferences _p;

  static Future<Store> open() async => Store._(await SharedPreferences.getInstance());

  String text(String key) => _p.getString(key) ?? '';
  bool flag(String key) => _p.getBool(key) ?? false;

  Future<void> setText(String key, String v) async {
    if (v.isEmpty) {
      await _p.remove(key);
    } else {
      await _p.setString(key, v);
    }
    notifyListeners();
  }

  Future<void> setFlag(String key, bool v) async {
    await _p.setBool(key, v);
    notifyListeners();
  }

  /// Everything currently stored, keyed as-is.
  ///
  /// Only `String` and `bool` values are included; anything else is skipped
  /// rather than cast, so a stray non-plannable entry can never poison an
  /// export. Empty text is already absent — `setText('')` removes the key.
  /// Reserved keys are excluded: `backup:*` so an export never contains the
  /// snapshot of another export, `ui:*` so UI state (dismissed notices) does
  /// not travel with a user's notes.
  Map<String, Object> dump() {
    final out = <String, Object>{};
    for (final key in _p.getKeys()) {
      if (key.startsWith(kBackupKeyPrefix) || key.startsWith(kUiKeyPrefix)) {
        continue;
      }
      final v = _p.get(key);
      // Separate branches so Dart promotes each to a non-nullable Object;
      // `v is String || v is bool` promotes to neither.
      if (v is String) {
        out[key] = v;
      } else if (v is bool) {
        out[key] = v;
      }
    }
    return out;
  }

  /// Write [values], dispatching on each value's runtime type.
  ///
  /// Writes go straight to SharedPreferences and notify **once** at the end,
  /// not per key — a full-year import is thousands of keys and notifying
  /// per key would rebuild every open page in a loop.
  ///
  /// With [exact], keys not present in [values] are deleted, so the result
  /// matches [values] exactly. Without it the write merges: keys the map does
  /// not mention are left alone.
  ///
  /// Values that are neither `String` nor `bool` are ignored, not cast —
  /// a hand-edited backup must not crash the app.
  Future<void> applyAll(Map<String, Object> values, {bool exact = false}) async {
    for (final entry in values.entries) {
      final v = entry.value;
      if (v is bool) {
        await _p.setBool(entry.key, v);
      } else if (v is String) {
        if (v.isEmpty) {
          await _p.remove(entry.key);
        } else {
          await _p.setString(entry.key, v);
        }
      }
    }
    if (exact) {
      for (final key in _p.getKeys().toList()) {
        if (key.startsWith(kBackupKeyPrefix)) continue;
        if (!values.containsKey(key)) await _p.remove(key);
      }
    }
    notifyListeners();
  }

  // ---- pre-import snapshot -------------------------------------------------
  //
  // One slot, held inside SharedPreferences under a reserved key so it
  // survives the same storage the notes do. It is the undo for a bad merge.

  /// When the current snapshot was taken, or null if there is none.
  DateTime? snapshotCreatedAt() {
    final json = _p.getString(kBackupSnapshotKey);
    if (json == null) return null;
    try {
      return decodeBackup(json).createdAt;
    } catch (_) {
      return null;
    }
  }

  /// Replace the snapshot with the notes as they are right now.
  ///
  /// Returns false if the write failed (for example browser storage is full) —
  /// a caller must then **abort** rather than merge without a way back.
  Future<bool> saveSnapshot() async {
    try {
      final json = encodeBackup(dump());
      await _p.setString(kBackupSnapshotKey, json);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restore the notes to exactly what the snapshot holds, and make the state
  /// being replaced the new snapshot — so tapping restore again undoes it.
  ///
  /// Returns false when there is no snapshot or it cannot be read.
  Future<bool> restoreSnapshot() async {
    final json = _p.getString(kBackupSnapshotKey);
    if (json == null) return false;
    try {
      final snapshot = decodeBackup(json);
      final current = encodeBackup(dump());
      await applyAll(snapshot.notes, exact: true);
      await _p.setString(kBackupSnapshotKey, current);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
