import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/holiday_widgets.dart';

/// Page 2: 12 mini calendars + event banner.
class YearPage extends StatelessWidget {
  const YearPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlannerPage(
      activeMonth: null,
      tabsOpenMonthView: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$planYear', style: T.serif(40)),
                  Text('YEAR AT A GLANCE',
                      style: T.sans(12, color: C.gold, w: FontWeight.w700, spacing: 3)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(toArabicDigits(planYear),
                    textDirection: TextDirection.rtl, style: T.arDisplay(44)),
                Text('نظرة على السنة',
                    textDirection: TextDirection.rtl, style: T.ar(13, color: C.gold)),
              ]),
            ]),
            const SizedBox(height: 10),
            const DottedRule(),
          ]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 700 ? 4 : 3;
          return Wrap(
            spacing: 14,
            runSpacing: 18,
            children: [
              for (var m = 1; m <= 12; m++)
                SizedBox(width: (c.maxWidth - 14 * (cols - 1)) / cols, child: MiniMonth(month: m)),
            ],
          );
        }),
        const SizedBox(height: 20),
        const HolidayList(),
        const SizedBox(height: 14),
        _EventBanner(event: events.first),
        const SizedBox(height: 6),
        Text('Tap a month to open it. Red circles are public holidays; the gold circle is World Arabic Language Day.',
            style: T.sans(10, color: C.navy.withValues(alpha: .6))),
      ]),
    );
  }
}

class MiniMonth extends StatelessWidget {
  const MiniMonth({super.key, required this.month});
  final int month;

  @override
  Widget build(BuildContext context) {
    final blanks = leadingBlanks(planYear, month);
    final total = daysInMonth(planYear, month);
    final cells = <Widget>[];
    for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
      cells.add(Center(child: Text(d, style: T.sans(8, color: C.navy.withValues(alpha: .6), w: FontWeight.w700))));
    }
    for (var i = 0; i < blanks; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= total; day++) {
      final col = (blanks + day - 1) % 7;
      final weekend = col >= 5;
      final d = DateTime(planYear, month, day);
      final ev = isEventDay(d);
      final hol = isHoliday(d);
      cells.add(Center(
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: ev
              ? const BoxDecoration(color: C.gold, shape: BoxShape.circle)
              : (hol
                  ? BoxDecoration(
                      shape: BoxShape.circle, border: Border.all(color: C.holiday, width: 1.3))
                  : null),
          child: Text('$day',
              style: T.sans(9.5,
                  color: ev ? Colors.white : (hol ? C.holiday : (weekend ? C.gold : C.navy)),
                  w: (ev || hol) ? FontWeight.w700 : FontWeight.w400)),
        ),
      ));
    }
    return GestureDetector(
      onTap: () => AppScope.of(context).openMonth(month, switchToMonthView: true),
      behavior: HitTestBehavior.opaque,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(monthsEn[month - 1], style: T.serif(14)),
            Text(monthsAr[month - 1], textDirection: TextDirection.rtl, style: T.arDisplay(14)),
          ]),
          Container(height: 1.5, color: C.gold, margin: const EdgeInsets.symmetric(vertical: 4)),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: cells,
          ),
        ]),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event});
  final PlannerEvent event;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.input,
          border: Border.all(color: C.line, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            Container(width: 22, height: 22, decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${event.date.day} December', style: T.sans(13, w: FontWeight.w700)),
                TextSpan(text: ': ${event.en}', style: T.sans(13)),
              ])),
            ),
            Text(event.ar, textDirection: TextDirection.rtl, style: T.ar(14, color: C.gold)),
          ]),
        ),
      );
}
