/// Version of this build.
///
/// This is what the update check compares against release tags, so it must
/// match the `version:` field in pubspec.yaml. [test/version_test.dart] asserts
/// that on every run — if the two drift apart the tests fail, so a stale
/// constant cannot ship and quietly never report an update.
///
/// The build number after `+` in pubspec is not part of this: release tags are
/// `v0.2.48`-style and match the build name only.
const String kAppVersion = '0.2.49';
