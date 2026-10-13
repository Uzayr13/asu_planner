import 'package:flutter_test/flutter_test.dart';
import 'package:asu_planner/data/holidays.dart';

void main() {
  test('16 public holidays, all in 2027, no duplicates', () {
    expect(holidays.length, 16);
    final dates = holidays.map((h) => h.date).toSet();
    expect(dates.length, 16);
    expect(holidays.every((h) => h.date.year == 2027), isTrue);
  });

  test('Ganesh Chaturthi on Sunday 5 Sep has a day in lieu on Monday 6 Sep', () {
    expect(DateTime(2027, 9, 5).weekday, DateTime.sunday);
    expect(isHoliday(DateTime(2027, 9, 5)), isTrue);
    expect(isHoliday(DateTime(2027, 9, 6)), isTrue);
  });

  test('Assumption (Sunday 15 Aug) is not on the 2027 Cabinet list', () {
    expect(isHoliday(DateTime(2027, 8, 15)), isFalse);
  });

  test('only Eid-Ul-Fitr is provisional', () {
    final p = holidays.where((h) => h.provisional).toList();
    expect(p.length, 1);
    expect(p.single.date, DateTime(2027, 3, 10));
  });

  test('holidays outside 2027 are ignored', () {
    expect(holidaysOn(DateTime(2026, 12, 25)), isEmpty);
  });

  test('month filter', () {
    expect(holidaysInMonth(11).length, 2);
    expect(holidaysInMonth(6), isEmpty);
  });
}
