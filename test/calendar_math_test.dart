import 'package:flutter_test/flutter_test.dart';
import 'package:asu_planner/data/calendar_math.dart';

void main() {
  test('Jan 2027 starts on Friday (4 blanks, Monday-first)', () {
    expect(leadingBlanks(2027, 1), 4);
    expect(daysInMonth(2027, 1), 31);
  });

  test('Feb 2027 has 28 days and starts on Monday', () {
    expect(daysInMonth(2027, 2), 28);
    expect(leadingBlanks(2027, 2), 0);
  });

  test('365 day pages, first 1 Jan, last 31 Dec', () {
    expect(dayAt(0), DateTime(2027, 1, 1));
    expect(dayAt(dayCount - 1), DateTime(2027, 12, 31));
    expect(dayIndex(DateTime(2027, 12, 31)), 364);
  });

  test('53 week pages cover every day of 2027', () {
    expect(weekIndex(DateTime(2027, 1, 1)), 0);
    expect(weekIndex(DateTime(2027, 1, 4)), 1);
    expect(weekIndex(DateTime(2027, 12, 31)), 52);
    expect(weekMonday(0), DateTime(2026, 12, 28));
    expect(weekMonday(52), DateTime(2027, 12, 27));
  });
}
