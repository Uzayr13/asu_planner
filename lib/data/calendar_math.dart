/// Calendar helpers for the 2027-only planner. Weeks start on Monday.
library;

const planYear = 2027;
final yearStart = DateTime(planYear, 1, 1);
final yearEnd = DateTime(planYear, 12, 31);

/// The plan's coverage. The launch word starts on 18 December 2026 — the day of
/// the presentation — and the vocabulary runs through the end of 2027. The
/// calendar therefore spans one month further back than [planYear].
final coverageStart = DateTime(2026, 12, 18);
final coverageEnd = DateTime(planYear, 12, 31);

/// True when [d] falls inside the covered period.
bool inCoverage(DateTime d) =>
    !d.isBefore(DateTime(2026, 12, 18)) && !d.isAfter(coverageEnd);

/// Month page index: 0 = December 2026, 1..12 = January..December 2027.
int monthPageIndexOf(DateTime d) => d.year == 2026 ? 0 : d.month;

/// The first day of the month shown at [index] (see [monthPageIndexOf]).
DateTime monthPageDate(int index) =>
    index <= 0 ? DateTime(2026, 12, 1) : DateTime(planYear, index, 1);

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
