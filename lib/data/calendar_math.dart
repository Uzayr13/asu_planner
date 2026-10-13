/// Calendar helpers for the 2027-only planner. Weeks start on Monday.
library;

const planYear = 2027;
final yearStart = DateTime(planYear, 1, 1);
final yearEnd = DateTime(planYear, 12, 31);

bool inPlanYear(DateTime d) => d.year == planYear;

/// Blank cells before day 1 in a Monday-first grid.
int leadingBlanks(int year, int month) => DateTime(year, month, 1).weekday - 1;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

// ---- Day pages: 365 days, index 0 = 1 Jan 2027 ----
const dayCount = 365;
DateTime dayAt(int i) => DateTime(planYear, 1, 1 + i);
int dayIndex(DateTime d) => _utc(d).difference(_utc(yearStart)).inDays;

// ---- Week pages: 53 weeks. Week 1 = Mon 28 Dec 2026 (contains 1 Jan 2027).
// Days outside 2027 appear greyed out and are not editable. ----
const weekCount = 53;
DateTime weekMonday(int i) => DateTime(2026, 12, 28 + 7 * i);
int weekIndex(DateTime d) => _utc(d).difference(DateTime.utc(2026, 12, 28)).inDays ~/ 7;

DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
