import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../layout/layout.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/holiday_widgets.dart';
import '../widgets/month_words_band.dart';

/// MONTH VIEW: swipe between the 12 months.
class MonthView extends StatelessWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context) => PagedView(
        // 13 pages: December 2026 (the launch month) plus January..December
        // 2027. Without it the launch word of 18 Dec 2026 is unreachable.
        count: 13,
        indexOf: monthPageIndexOf,
        onPage: (app, i) {
          final first = monthPageDate(i);
          app.setDate(DateTime(first.year, first.month,
              app.date.day.clamp(1, daysInMonth(first.year, first.month))));
        },
        builder: (i) => MonthPage(date: monthPageDate(i)),
      );
}

class MonthPage extends StatefulWidget {
  const MonthPage({super.key, required this.date});

  /// First day of the month this page shows — 1 Dec 2026 through 1 Dec 2027.
  final DateTime date;

  @override
  State<MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  /// The words band sits above the grid and is not part of the base chrome
  /// estimate in `layout.dart`, so its height is measured and fed in. Anything
  /// added above the grid later must do the same — hand-tuning the constants
  /// is exactly how the grid ends up overflowing.
  final _bandKey = GlobalKey();
  double _bandHeight = 0;

  void _measureBand() {
    if (!mounted) return;
    final box = _bandKey.currentContext?.findRenderObject() as RenderBox?;
    final h = box?.size.height ?? 0;
    if (h > 0 && h != _bandHeight) {
      setState(() => _bandHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure every build, not once: collapsing the band changes its height
    // and the grid has to give that space back.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBand());
    final l = L.of(context);
    final month = widget.date.month;
    final year = widget.date.year;
    final blanks = leadingBlanks(year, month);
    final total = daysInMonth(year, month);
    final rows = ((blanks + total) / 7).ceil();
    // Row height comes from MediaQuery via L, not from a LayoutBuilder: this
    // page sits inside a SingleChildScrollView where LayoutBuilder reports
    // unbounded height. Deriving from that would produce infinity.
    final rowH = l.monthRowHeight(rows, extraChrome: _bandHeight);
    // Short rows cannot show a 3-6 line note field without overflowing the
    // cell, so scale the note field down with the cell.
    final noteMax = rowH >= 90 ? 6 : (rowH >= 70 ? 3 : 1);

    return PlannerPage(
      activeMonthIndex: monthPageIndexOf(widget.date),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: monthsEn[month - 1],
          subEn: '$year',
          titleAr: monthsAr[month - 1],
          subAr: toArabicDigits(year),
        ),
        // Both words of the month, at the top, side by side. Measured so the
        // grid can give back exactly the height it takes.
        KeyedSubtree(key: _bandKey, child: MonthWordsBand(month: month, year: year)),
        SizedBox(height: l.gapL),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: C.line)),
            child: Column(children: [
              Container(
                color: C.navy,
                padding: EdgeInsets.symmetric(vertical: l.gapS),
                child: Row(children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(children: [
                        Text(daysEn[i],
                            style: T.sans(11, color: Colors.white, w: FontWeight.w700, spacing: 1)),
                        Text(daysAr[i],
                            textDirection: TextDirection.rtl,
                            style: T.ar(10, color: Colors.white60)),
                      ]),
                    ),
                ]),
              ),
              for (var r = 0; r < rows; r++)
                // Tight height rather than IntrinsicHeight: rows then share the
                // viewport evenly and the whole month fits when it can.
                SizedBox(
                  height: rowH,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (var c = 0; c < 7; c++)
                      _cell(context, r * 7 + c - blanks + 1, total, c, noteMax),
                  ]),
                ),
            ]),
          ),
        ),
        SizedBox(height: l.gapXs),
        Text('Tap a date number to open that day. Tap a box to type in it.',
            style: T.sans(10, color: C.navy.withValues(alpha: .6))),
        SizedBox(height: l.gapM),
        HolidayList(month: month),
        SizedBox(height: l.gapM),
      ]),
    );
  }

  Widget _cell(BuildContext context, int day, int total, int col, int noteMax) {
    final inMonth = day >= 1 && day <= total;
    final weekend = col >= 5;
    final date = DateTime(widget.date.year, widget.date.month, day);
    final hol = inMonth ? holidaysOn(date) : const <Holiday>[];
    final evs = inMonth ? eventsOn(date) : const <PlannerEvent>[];
    final isHol = hol.isNotEmpty;
    final isEv = evs.isNotEmpty;
    final tint = isHol ? C.holiday : (isEv ? C.gold : null);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: inMonth ? tint?.withValues(alpha: .12) : const Color(0xFFB5ADA0),
          border: Border.all(color: C.line, width: .5),
        ),
        padding: const EdgeInsets.all(5),
        child: inMonth
            // ClipRect + OverflowBox: the row height is deliberately tight so
            // the whole month fits the viewport, so a day carrying several
            // holidays can have more content than the cell. Let the column
            // size to its content and clip it, rather than asserting overflow.
            ? ClipRect(
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topLeft,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => AppScope.of(context).openDay(date),
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: isEv
                            ? const BoxDecoration(color: C.gold, shape: BoxShape.circle)
                            : null,
                        child: Text('$day',
                            style: T.sans(14,
                                color: isEv
                                    ? Colors.white
                                    : (isHol ? C.holiday : (weekend ? C.gold : C.navy)),
                                w: FontWeight.w700)),
                      ),
                    ),
                    for (final h in hol) DayMark(text: h.en, color: C.holiday),
                    for (final e in evs) DayMark(text: e.en, color: C.gold),
                    const SizedBox(height: 3),
                    EditableBox(
                      storeKey: 'day:${dateKey(date)}',
                      minLines: 1,
                      maxLines: noteMax,
                      style: T.sans(10),
                    ),
                  ]),
                ),
              )
            : null,
      ),
    );
  }
}
