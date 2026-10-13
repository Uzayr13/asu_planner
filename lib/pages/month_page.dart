import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
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
    final blanks = leadingBlanks(planYear, month);
    final total = daysInMonth(planYear, month);
    final rows = ((blanks + total) / 7).ceil();

    return PlannerPage(
      activeMonth: month,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: monthsEn[month - 1],
          subEn: '$planYear',
          titleAr: monthsAr[month - 1],
          subAr: toArabicDigits(planYear),
        ),
        const SizedBox(height: 18),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: C.line)),
            child: Column(children: [
              Container(
                color: C.navy,
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (var c = 0; c < 7; c++) _cell(context, r * 7 + c - blanks + 1, total, c),
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text('Tap a date number to open that day. Tap a box to type in it.',
            style: T.sans(10, color: C.navy.withValues(alpha: .6))),
        const SizedBox(height: 14),
        HolidayList(month: month),
        const SizedBox(height: 14),
        WordCard(month: month),
      ]),
    );
  }

  Widget _cell(BuildContext context, int day, int total, int col) {
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
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          color: inMonth ? tint?.withValues(alpha: .12) : const Color(0xFFB5ADA0),
          border: Border.all(color: C.line, width: .5),
        ),
        padding: const EdgeInsets.all(5),
        child: inMonth
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                Expanded(
                  child: EditableBox(
                    storeKey: 'day:${dateKey(date)}',
                    minLines: 3,
                    maxLines: 6,
                    style: T.sans(10),
                  ),
                ),
              ])
            : null,
      ),
    );
  }
}
