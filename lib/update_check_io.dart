/// The thin platform edge for the update check — the only file that knows HTTP
/// exists. `update_check.dart` deals in strings so it stays pure and testable.
///
/// **Every failure returns null.** Offline, rate-limited (GitHub allows 60
/// unauthenticated requests an hour), a 404, a parse error — all the same
/// answer: we don't know, and the app should behave as if there is no update.
/// A failed check must never disturb the person using the planner.
library;

import 'package:http/http.dart' as http;

import 'update_check.dart';

/// The GitHub releases feed for this project.
const String kReleasesApiUrl =
    'https://api.github.com/repos/Uzayr13/asu_planner/releases/latest';

/// The tag of the newest published release, e.g. `v0.2.49`.
///
/// Returns null when it cannot be determined. Never throws.
Future<String?> fetchLatestReleaseTag({http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final res = await c
        .get(Uri.parse(kReleasesApiUrl), headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    // Minimal field extraction: pulling in a JSON parser for one string is not
    // worth it, and a malformed body must not throw.
    final match = RegExp(r'"tag_name"\s*:\s*"([^"]+)"').firstMatch(res.body);
    if (match == null) return null;
    final tag = match.group(1)!;
    return parseVersion(tag) == null ? null : tag;
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Convenience: the newest release tag if it is newer than [current],
/// otherwise null. Combines the fetch with [isNewerVersion] so callers only
/// deal in "is there something to install".
Future<String?> fetchNewerReleaseTag(String current) async {
  final tag = await fetchLatestReleaseTag();
  if (tag == null) return null;
  return isNewerVersion(tag, current) ? tag : null;
}
