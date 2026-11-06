import 'package:flutter_test/flutter_test.dart';

import 'package:asu_planner/data/content.dart';

/// The schedule is the contract the whole word feature rests on. These tests
/// assert its shape rather than trusting a hand-written table of 25 dates.
void main() {
  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  test('has exactly 25 words', () {
    expect(words.length, 25, reason: '1 launch word + 2 per month for 12 months');
  });

  test('the launch word is 18–31 Dec 2026 and is first', () {
    expect(wordIndexAt(d(2026, 12, 18)), 1);
    expect(words.first.from, d(2026, 12, 18));
    expect(words.first.to, d(2026, 12, 31));
    expect(words.first.en, 'Market');
  });

  test('every range starts on a half-month boundary', () {
    // 1st or 16th, except the launch word which starts on the 18th.
    for (var i = 1; i < words.length; i++) {
      expect([1, 16].contains(words[i].from.day), isTrue,
          reason: 'word ${i + 1} starts ${words[i].from}');
    }
  });

  test('ranges are contiguous — no gaps, no overlaps', () {
    for (var i = 0; i < words.length - 1; i++) {
      final a = words[i];
      final b = words[i + 1];
      expect(b.from.isAfter(a.to), isTrue,
          reason: 'word ${i + 2} starts before word ${i + 1} ends');
      expect(b.from.difference(a.to).inDays, 1,
          reason: 'word ${i + 2} should start the day after word ${i + 1} ends');
    }
  });

  test('no date falls into two words', () {
    for (final w in words) {
      var d0 = w.from;
      while (!d0.isAfter(w.to)) {
        final hits = words.where((x) => x.contains(d0)).length;
        expect(hits, 1, reason: '$d0 is covered by $hits words');
        d0 = d0.add(const Duration(days: 1));
      }
    }
  });

  test('wordAt resolves every boundary correctly', () {
    expect(wordAt(d(2026, 12, 17)), isNull, reason: 'before the launch');
    expect(wordAt(d(2026, 12, 18))?.en, 'Market');
    expect(wordAt(d(2026, 12, 31))?.en, 'Market');
    expect(wordAt(d(2027, 1, 1))?.en, 'Sugar', reason: 'new year, new word');
    expect(wordAt(d(2027, 1, 15))?.en, 'Sugar');
    expect(wordAt(d(2027, 1, 16))?.en, 'Lemon', reason: 'half-month boundary');
    expect(wordAt(d(2027, 1, 31))?.en, 'Lemon');
    expect(wordAt(d(2027, 12, 31))?.en, 'Arsenal', reason: 'the last word');
    expect(wordAt(d(2028, 1, 1)), isNull, reason: 'after the schedule');
  });

  test('February respects its own length', () {
    expect(wordAt(d(2027, 2, 28))?.en, 'Mattress');
    expect(wordAt(d(2027, 3, 1))?.en, 'Coffee');
  });

  test('wordIndexAt maps 1..25 in schedule order', () {
    for (var i = 0; i < words.length; i++) {
      expect(wordIndexAt(words[i].from), i + 1);
      expect(wordIndexAt(words[i].to), i + 1);
    }
    expect(wordIndexAt(d(2026, 12, 17)), isNull);
    expect(wordIndexAt(d(2028, 1, 1)), isNull);
  });

  test('every word has its content', () {
    for (final w in words) {
      expect(w.en, isNotEmpty);
      expect(w.ar, isNotEmpty);
      expect(w.translit, isNotEmpty);
      expect(w.fr, isNotEmpty);
      expect(w.noteEn, isNotEmpty);
    }
  });

  test('rangeLabel shows the year only where it differs from 2027', () {
    expect(words.first.rangeLabel, '18–31 Dec 2026',
        reason: 'the launch word is in 2026');
    expect(wordAt(d(2027, 1, 1))?.rangeLabel, '1–15 Jan');
    expect(wordAt(d(2027, 1, 16))?.rangeLabel, '16–31 Jan');
    expect(wordAt(d(2027, 2, 16))?.rangeLabel, '16–28 Feb');
  });

  test('wordsInMonth returns both halves of a 2027 month', () {
    final jan = wordsInMonth(1);
    expect(jan.length, 2);
    expect(jan.first.en, 'Sugar');
    expect(jan.last.en, 'Lemon');
  });

  test('the launch month has only its single word', () {
    final dec26 = wordsInMonth(12, year: 2026);
    expect(dec26.length, 1);
    expect(dec26.single.en, 'Market');
  });
}
