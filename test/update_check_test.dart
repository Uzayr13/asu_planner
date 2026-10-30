import 'package:flutter_test/flutter_test.dart';

import 'package:asu_planner/update_check.dart';

void main() {
  group('parseVersion', () {
    test('reads bare and v-prefixed forms', () {
      expect(parseVersion('0.2.49'), [0, 2, 49]);
      expect(parseVersion('v0.2.49'), [0, 2, 49]);
      expect(parseVersion('V0.2.49'), [0, 2, 49]);
      expect(parseVersion('  v1.0.0  '), [1, 0, 0]);
    });

    test('rejects anything that is not exactly three numbers', () {
      expect(parseVersion(''), isNull);
      expect(parseVersion('abc'), isNull);
      expect(parseVersion('v'), isNull);
      expect(parseVersion('1.2'), isNull);
      expect(parseVersion('1.2.3.4'), isNull);
      expect(parseVersion('1.2.x'), isNull);
      expect(parseVersion('latest'), isNull);
    });
  });

  group('isNewerVersion', () {
    test('a higher patch is newer', () {
      expect(isNewerVersion('v0.2.50', '0.2.49'), isTrue);
      expect(isNewerVersion('0.2.49', 'v0.2.48'), isTrue);
    });

    test('a higher minor or major is newer', () {
      expect(isNewerVersion('0.3.0', '0.2.49'), isTrue);
      expect(isNewerVersion('1.0.0', '0.99.99'), isTrue);
    });

    test('equal is not newer', () {
      expect(isNewerVersion('0.2.49', '0.2.49'), isFalse);
      expect(isNewerVersion('v0.2.49', '0.2.49'), isFalse,
          reason: 'the v prefix is not a difference');
    });

    test('an older release is not newer', () {
      expect(isNewerVersion('0.2.48', '0.2.49'), isFalse);
      expect(isNewerVersion('0.1.99', '0.2.0'), isFalse);
    });

    test('malformed input is never newer', () {
      expect(isNewerVersion('', '0.2.49'), isFalse);
      expect(isNewerVersion('abc', '0.2.49'), isFalse);
      expect(isNewerVersion('latest', '0.2.49'), isFalse);
      expect(isNewerVersion('v0.2', '0.2.49'), isFalse);
      expect(isNewerVersion('99.0.0', 'not-a-version'), isFalse,
          reason: 'a bad current version must not make everything look newer');
    });

    test('a huge version still compares numerically, not lexically', () {
      expect(isNewerVersion('0.10.0', '0.9.0'), isTrue,
          reason: '10 is greater than 9; string comparison would say otherwise');
    });
  });

  group('tagLabel', () {
    test('normalises to a leading v', () {
      expect(tagLabel('0.2.49'), 'v0.2.49');
      expect(tagLabel('v0.2.49'), 'v0.2.49');
    });
  });
}
