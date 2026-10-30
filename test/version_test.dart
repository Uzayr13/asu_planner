import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:asu_planner/version.dart';

/// Guards against [kAppVersion] drifting from pubspec.yaml.
///
/// The update check compares the running version against release tags. If the
/// constant is stale the app would silently never report an update, so this
/// fails the build instead.
void main() {
  test('kAppVersion matches the version field in pubspec.yaml', () {
    final pubspec =
        File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version: field');

    // pubspec carries a build number after '+'; release tags do not.
    final declared = match!.group(1)!.split('+').first;
    expect(kAppVersion, declared,
        reason: 'lib/version.dart is out of step with pubspec.yaml — '
            'the update check would never fire. Bump both together.');
  });

  test('kAppVersion looks like a release tag', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(kAppVersion), isTrue,
        reason: 'tags are v<major>.<minor>.<patch>, so the constant must be bare');
  });
}
