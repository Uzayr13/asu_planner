import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../layout/layout.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/holiday_widgets.dart';

/// MONTH VIEW: swipe between the 12 months.
class MonthView extends StatelessWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context) => PagedView(
        count: 12,
        indexOf: (d) => d.month - 1,
        onPage: (app, i) => app.setDate(
            DateTime(planYear, i + 1, app.date.day.clamp(1, daysInMonth(planYear, i + 1)))),
        builder: (i) => MonthPage(month: i + 1),
      );
}

class MonthPage extends StatelessWidget {
  const MonthPage({super.key, required this.month});
  final int month; // 1..12

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final blanks = leadingBlanks(planYear, month);
    final total = daysInMonth(planYear, month);
    final rows = ((blanks + total) / 7).ceil();
    // Row height comes from MediaQuery via L, not from a LayoutBuilder: this
    // page sits inside a SingleChildScrollView where LayoutBuilder reports
    // unbounded height. Deriving from that would produce infinity.
    final rowH = l.monthRowHeight(rows);
    // Short rows cannot show a 3-6 line note field without overflowing the
    // cell, so scale the note field down with the cell.
    final noteMax = rowH >= 90 ? 6 : (rowH >= 70 ? 3 : 1);

    return PlannerPage(
      activeMonth: month,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: monthsEn[month - 1],
          subEn: '$planYear',
          titleAr: monthsAr[month - 1],
          subAr: toArabicDigits(planYear),
        ),
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
        WordCard(month: month),
      ]),
    );
  }

  Widget _cell(BuildContext context, int day, int total, int col, int noteMax) {
    final inMonth = day >= 1 && day <= total;
    final weekend = col >= 5;
    final date = DateTime(planYear, month, day);
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
