import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asu_planner/backup/backup.dart';
import 'package:asu_planner/store.dart';

void main() {
  group('encode / decode', () {
    test('round-trips text and flags without losing types', () {
      const notes = <String, Object>{
        'day:2027-01-04': 'Call the venue',
        'dvf:2027-01-04:0': true,
        'habit:2026-12-28:1': false,
        'word:0:0': 'سكر',
      };
      final json = encodeBackup(notes);
      final back = decodeBackup(json);
      expect(back.notes, equals(notes));
    });

    test('drops empty strings rather than writing them', () {
      final json = encodeBackup({'day:2027-01-04': '', 'day:2027-01-05': 'kept'});
      final back = decodeBackup(json);
      expect(back.notes.containsKey('day:2027-01-04'), isFalse,
          reason: 'empty text means "no note"; writing it would delete on import');
      expect(back.notes['day:2027-01-05'], 'kept');
    });

    test('keeps false flags — a false is a real value, not an absence', () {
      final back = decodeBackup(encodeBackup({'habit:2026-12-28:0': false}));
      expect(back.notes['habit:2026-12-28:0'], isFalse);
    });

    test('preserves the string/bool distinction in the file itself', () {
      final json = encodeBackup({'a': 'true', 'b': true});
      expect(json, contains('"a": "true"'), reason: 'text stays quoted');
      expect(json, contains('"b": true'), reason: 'flag stays a JSON boolean');
      final back = decodeBackup(json);
      expect(back.notes['a'], isA<String>());
      expect(back.notes['b'], isA<bool>());
    });

    test('records a formatVersion so a later schema can migrate', () {
      expect(encodeBackup(const {}), contains('"formatVersion": 1'));
      expect(decodeBackup(encodeBackup(const {})).formatVersion, 1);
    });

    test('rejects truncated JSON', () {
      expect(() => decodeBackup('{"formatVersion": 1, "notes": {'),
          throwsA(isA<BackupFormatException>()));
    });

    test('rejects a missing or non-integer formatVersion', () {
      expect(() => decodeBackup('{"notes": {}}'),
          throwsA(isA<BackupFormatException>()));
      expect(() => decodeBackup('{"formatVersion": "1", "notes": {}}'),
          throwsA(isA<BackupFormatException>()));
    });

    test('rejects an unknown formatVersion rather than guessing', () {
      expect(() => decodeBackup('{"formatVersion": 99, "notes": {}}'),
          throwsA(isA<BackupFormatException>()));
    });

    test('rejects a missing notes object', () {
      expect(() => decodeBackup('{"formatVersion": 1}'),
          throwsA(isA<BackupFormatException>()));
    });

    test('rejects a value that is neither text nor flag', () {
      expect(() => decodeBackup('{"formatVersion": 1, "notes": {"k": 42}}'),
          throwsA(isA<BackupFormatException>()));
      expect(() => decodeBackup('{"formatVersion": 1, "notes": {"k": null}}'),
          throwsA(isA<BackupFormatException>()));
    });

    test('reports the offending key so a user can find it', () {
      expect(
          () => decodeBackup('{"formatVersion": 1, "notes": {"bad:1": 42}}'),
          throwsA(predicate((e) =>
              e is BackupFormatException && e.message.contains('bad:1'))));
    });
  });

  group('merge — backup wins, device keeps what the file lacks', () {
    test('conflicting key: the backup wins', () {
      final merged = mergeNotes({'day:2027-01-04': 'newer'}, {'day:2027-01-04': 'older'});
      expect(merged['day:2027-01-04'], 'older',
          reason: 'backup wins by design');
    });

    test('key only on the device is kept', () {
      final merged = mergeNotes({'day:2027-01-04': 'mine'}, const {});
      expect(merged['day:2027-01-04'], 'mine');
    });

    test('key only in the file is added', () {
      final merged = mergeNotes(const {}, {'day:2027-01-05': 'from file'});
      expect(merged['day:2027-01-05'], 'from file');
    });

    test('merging never drops keys', () {
      final existing = {'a': '1', 'b': '2', 'c': '3'};
      final merged = mergeNotes(existing, {'b': 'changed', 'd': 'new'});
      expect(merged.keys.toSet(), {'a', 'b', 'c', 'd'});
    });

    test('a flag can overwrite text of the same key — type comes from the file', () {
      final merged = mergeNotes({'dvf:2027-01-04:0': false}, {'dvf:2027-01-04:0': true});
      expect(merged['dvf:2027-01-04:0'], isA<bool>());
      expect(merged['dvf:2027-01-04:0'], isTrue);
    });
  });

  group('diffNotes', () {
    test('classifies added, overwritten and unchanged', () {
      final d = diffNotes(
        {'a': '1', 'b': '2', 'c': '3'},
        {'b': '2', 'c': 'CHANGED', 'd': 'new'},
      );
      expect(d.added, 1, reason: 'd');
      expect(d.overwritten, 1, reason: 'c');
      expect(d.unchanged, 1, reason: 'b');
      expect(d.total, 3);
    });

    test('is a no-op when nothing would change', () {
      final d = diffNotes({'a': '1'}, {'a': '1'});
      expect(d.isNoOp, isTrue);
    });

    test('an empty file changes nothing', () {
      expect(diffNotes({'a': '1'}, const {}).isNoOp, isTrue);
    });

    test('summary is human readable', () {
      final d = diffNotes(const {}, {'a': '1'});
      expect(d.summary, '1 to add · 0 to replace · 0 unchanged');
    });
  });

  group('file names', () {
    test('export name carries the plan year and the date', () {
      expect(backupFileName(when: DateTime(2026, 10, 16)),
          'asu-planner-2027-2026-10-16.json');
    });

    test('snapshot name is unmistakable', () {
      expect(snapshotFileName(when: DateTime(2026, 10, 16)),
          'asu-planner-PRE-IMPORT-2026-10-16.json');
    });
  });

  group('store integration', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('dump -> encode -> decode -> applyAll round-trips exactly', () async {
      final source = await Store.open();
      await source.setText('day:2027-01-04', 'Call the venue');
      await source.setText('word:0:0', 'سكر');
      await source.setFlag('habit:2026-12-28:0', true);
      await source.setFlag('habit:2026-12-28:1', false);

      final encoded = encodeBackup(source.dump());
      final restored = await Store.open();
      await restored.applyAll(decodeBackup(encoded).notes);

      expect(restored.dump(), equals(source.dump()));
    });

    test('setText("") removes, so an empty note never reaches an export', () async {
      final s = await Store.open();
      await s.setText('day:2027-01-04', 'temp');
      await s.setText('day:2027-01-04', '');
      expect(s.dump().containsKey('day:2027-01-04'), isFalse);
    });

    test('applyAll ignores values that are neither text nor flag', () async {
      final s = await Store.open();
      await s.applyAll({'ok': 'text', 'bad': 42});
      expect(s.text('ok'), 'text');
      expect(s.dump().containsKey('bad'), isFalse,
          reason: 'a number must not be cast into a text or flag slot');
    });

    test('applyAll keeps the string and flag buckets separate', () async {
      final s = await Store.open();
      await s.applyAll({'k': true});
      expect(s.flag('k'), isTrue);
      expect(() => s.dump()['k'], returnsNormally);
      expect(s.dump()['k'], isA<bool>());
    });

    test('a full merge leaves device-only notes intact', () async {
      final device = await Store.open();
      await device.setText('day:2027-01-04', 'device only');
      await device.setText('day:2027-01-05', 'will be replaced');

      final incoming = {
        'day:2027-01-05': 'from backup',
        'day:2027-01-06': 'brand new',
      };
      await device.applyAll(mergeNotes(device.dump(), incoming));

      expect(device.text('day:2027-01-04'), 'device only', reason: 'kept');
      expect(device.text('day:2027-01-05'), 'from backup', reason: 'backup wins');
      expect(device.text('day:2027-01-06'), 'brand new', reason: 'added');
    });
  });
}
