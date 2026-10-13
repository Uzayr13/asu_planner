import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../layout/layout.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/holiday_widgets.dart';

/// WEEK VIEW: swipe between the 53 weeks of 2027.
class WeekView extends StatelessWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context) => PagedView(
        count: weekCount,
        indexOf: weekIndex,
        onPage: (app, i) {
          final monday = weekMonday(i);
          // keep same weekday if possible, never leave 2027
          var d = DateTime(monday.year, monday.month, monday.day + (app.date.weekday - 1));
          if (!inPlanYear(d)) d = d.year < planYear ? yearStart : yearEnd;
          app.setDate(d);
        },
        builder: (i) => WeekPage(index: i),
      );
}

class WeekPage extends StatelessWidget {
  const WeekPage({super.key, required this.index});
  final int index; // 0..52

  @override
  Widget build(BuildContext context) {
    final monday = weekMonday(index);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    // Clip the header range to 2027
    final first = monday.year < planYear ? yearStart : monday;
    final last = sunday.year > planYear ? yearEnd : sunday;
    final key = dateKey(monday);
    final n = index + 1;

    String rangeEn(DateTime a, DateTime b) =>
        '${a.day} ${monthsEn[a.month - 1].substring(0, 3).toUpperCase()} - '
        '${b.day} ${monthsEn[b.month - 1].substring(0, 3).toUpperCase()} $planYear';
    String rangeAr(DateTime a, DateTime b) =>
        '${toArabicDigits(a.day)} ${monthsAr[a.month - 1]} - '
        '${toArabicDigits(b.day)} ${monthsAr[b.month - 1]} ${toArabicDigits(planYear)}';

    return PlannerPage(
      activeMonth: first.month,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: 'Week $n',
          subEn: rangeEn(first, last),
          titleAr: 'الأسبوع ${toArabicDigits(n)}',
          subAr: rangeAr(first, last),
          titleSize: 36,
        ),
        const SizedBox(height: 14),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _Priorities(weekKey: key)),
            const SizedBox(width: 12),
            Expanded(child: WordCard(month: last.month, compact: true)),
          ]),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < 7; i++)
          _DayRow(date: DateTime(monday.year, monday.month, monday.day + i), index: i),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: C.input,
              border: Border.all(color: C.line, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            // LayoutBuilder is safe for WIDTH here; only its height is
            // unbounded inside the scroll view (see L docs).
            child: LayoutBuilder(builder: (context, c) {
              final l = L.of(context);
              final dot = l.habitDotSize(c.maxWidth * .55);
              final label = Text('ONE ARABIC WORD A DAY',
                  style: T.sans(11, color: C.gold, w: FontWeight.w700, spacing: 1.5));
              final dots = [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: EdgeInsets.only(left: l.gapS),
                    child: HabitDot(
                      storeKey: habitKey(DateTime(monday.year, monday.month, monday.day + i)),
                      label: 'MTWTFSS'[i],
                      size: dot,
                    ),
                  ),
              ];
              // Below 420pt of content the label wraps to three lines beside
              // the dots — stack them instead.
              return l.compactHabitStrip
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, SizedBox(height: l.gapS), Row(children: dots)])
                  : Row(children: [Expanded(child: label), ...dots]);
            }),
          ),
        ),
        const SizedBox(height: 6),
        Text('Tap a day name to open that day. Tap a box to type in it.',
            style: T.sans(10, color: C.navy.withValues(alpha: .6))),
      ]),
    );
  }
}

class _Priorities extends StatelessWidget {
  const _Priorities({required this.weekKey});
  final String weekKey;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.input.withValues(alpha: .35),
        border: Border.all(color: C.line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRIORITIES', style: T.sans(10, color: C.gold, w: FontWeight.w700, spacing: 2)),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: store.flag('prio:$weekKey:$i'),
                  onChanged: (v) => store.setFlag('prio:$weekKey:$i', v ?? false),
                  side: const BorderSide(color: C.gold, width: 1.5),
                  activeColor: C.gold,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: EditableBox(storeKey: 'wk:$weekKey:p$i', style: T.sans(11))),
            ]),
          ),
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.index});
  final DateTime date;
  final int index;

  @override
  Widget build(BuildContext context) {
    final active = inPlanYear(date);
    final weekend = index >= 5;
    final hol = active ? holidaysOn(date) : const <Holiday>[];
    final evs = active ? eventsOn(date) : const <PlannerEvent>[];
    final col = !active
        ? C.navy.withValues(alpha: .3)
        : (hol.isNotEmpty ? C.holiday : (weekend ? C.gold : C.navy));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
        padding: const EdgeInsets.symmetric(vertical: 6),
        // Min-height, not a fixed 84: a day carrying holidays and events used
        // to RenderFlex-overflow the row. IntrinsicHeight lets the row grow
        // with its content and with the system text scale.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: active ? () => AppScope.of(context).openDay(date) : null,
                child: SizedBox(
                  width: 62,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(daysEn[index][0] + daysEn[index].substring(1).toLowerCase(),
                            style: T.sans(14, color: col, w: FontWeight.w700)),
                        Text('${date.day} ${monthsEn[date.month - 1].substring(0, 3)}',
                            style: T.sans(10.5, color: C.navy.withValues(alpha: .6))),
                      ]),
                ),
              ),
              Expanded(
                child: active
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final h in hol) DayMark(text: h.en, color: C.holiday, size: 10),
                        for (final e in evs) DayMark(text: e.en, color: C.gold, size: 10),
                        EditableBox(
                          storeKey: 'day:${dateKey(date)}',
                          minLines: 2,
                          maxLines: 4,
                          style: T.sans(11),
                        ),
                      ])
                    : Container(color: const Color(0xFFB5ADA0).withValues(alpha: .5)),
              ),
              SizedBox(
                width: 70,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(daysAr[index],
                          textDirection: TextDirection.rtl,
                          style: T.ar(14, color: col, w: FontWeight.w700)),
                      Text(toArabicDigits(date.day),
                          textDirection: TextDirection.rtl,
                          style: T.ar(11, color: C.navy.withValues(alpha: .6))),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
