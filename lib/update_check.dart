/// Decides whether a release is newer than the running build.
///
/// Pure Dart: no Flutter, no network. Everything here is a function over
/// strings so it is fully unit-testable, and the platform edge in
/// `update_check_io.dart` stays trivial.
///
/// Two rules matter:
///
/// * **Anything unparseable is not newer.** A malformed response must never
///   prompt someone to "update" to nothing.
/// * **Equal is not newer.** A user who just updated must not be nagged.
library;

/// Parse a version into comparable parts.
///
/// Accepts `0.2.49` and `v0.2.49`. Returns null for anything else — including
/// `1.2`, `1.2.3.4`, `abc`, or an empty string.
List<int>? parseVersion(String raw) {
  final cleaned = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(cleaned);
  if (match == null) return null;
  return [
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

/// True when [latest] is a strictly newer release than [current].
///
/// Both accept a leading `v`. Returns false when either side fails to parse,
/// when they are equal, or when [latest] is older — a bad response from the
/// network must never look like an update.
bool isNewerVersion(String latest, String current) {
  final a = parseVersion(latest);
  final b = parseVersion(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Suggested label for a release, e.g. `v0.2.49`.
///
/// Guarantees exactly one leading `v`, so a bare `0.2.49` and a `v0.2.49`
/// present identically in the UI.
String tagLabel(String tag) {
  final bare = tag.trim().replaceFirst(RegExp(r'^[vV]'), '');
  return 'v$bare';
}
