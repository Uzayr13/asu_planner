import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../layout/layout.dart';
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$planYear', style: T.serif(40)),
                  ),
                  Text('YEAR AT A GLANCE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.sans(12, color: C.gold, w: FontWeight.w700, spacing: 3)),
                ]),
              ),
              // Align keeps the Arabic block on the right edge; Flexible alone
              // left it floating mid-header.
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(toArabicDigits(planYear),
                          textDirection: TextDirection.rtl, style: T.arDisplay(44)),
                    ),
                    Text('نظرة على السنة',
                        textDirection: TextDirection.rtl, style: T.ar(13, color: C.gold)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            const DottedRule(),
          ]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          // 2 columns on xs: at 320pt with 3 columns a day cell is ~12pt wide,
          // too small for a readable marker. Fluid marker scaling alone is not
          // enough — the column count has to drop too.
          final cols = L.of(context).yearCols;
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
    // LayoutBuilder for WIDTH only — safe inside the scroll view, unlike its
    // height (see L docs). The marker must track the cell or it overflows:
    // at 375pt a 7-wide cell is ~14.6pt and the old marker was a fixed 18.
    return LayoutBuilder(builder: (context, c) {
      final l = L.of(context);
      final marker = l.miniMarker(c.maxWidth / 7);
      final blanks = leadingBlanks(planYear, month);
      final total = daysInMonth(planYear, month);
      final cells = <Widget>[];
      for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
        cells.add(Center(
            child: Text(d,
                style: T.sans(8, color: C.navy.withValues(alpha: .6), w: FontWeight.w700))));
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
            width: marker,
            height: marker,
          alignment: Alignment.center,
          decoration: ev
              ? const BoxDecoration(color: C.gold, shape: BoxShape.circle)
              : (hol
                  ? BoxDecoration(
                      shape: BoxShape.circle, border: Border.all(color: C.holiday, width: 1.3))
                  : null),
          child: Text('$day',
              style: T.sans(marker * .55,
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
              Flexible(
                child: Text(monthsEn[month - 1],
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: T.serif(14)),
              ),
              Flexible(
                child: Text(monthsAr[month - 1],
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.arDisplay(14)),
              ),
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
    });
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
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(event.ar,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.ar(14, color: C.gold)),
              ),
            ),
          ]),
        ),
      );
}
