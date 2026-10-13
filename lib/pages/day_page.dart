import 'package:flutter/material.dart';

import '../data/calendar_math.dart';
import '../data/content.dart';
import '../data/holidays.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// DAY VIEW: swipe between the 365 days of 2027.
class DayView extends StatelessWidget {
  const DayView({super.key});

  @override
  Widget build(BuildContext context) => PagedView(
        count: dayCount,
        indexOf: dayIndex,
        onPage: (app, i) => app.setDate(dayAt(i)),
        builder: (i) => DayPage(date: dayAt(i)),
      );
}

class DayPage extends StatelessWidget {
  const DayPage({super.key, required this.date});
  final DateTime date;

  static const firstHour = 6;
  static const lastHour = 21;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final k = dateKey(date);
    final di = date.weekday - 1;
    final weekend = di >= 5;
    final hol = holidaysOn(date);
    final evs = eventsOn(date);

    Widget label(String en, String ar) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Expanded(
                child: Text(en, style: T.sans(11, color: C.gold, w: FontWeight.w700, spacing: 2)),
              ),
              Text(ar, textDirection: TextDirection.rtl, style: T.ar(13, color: C.gold)),
            ]),
          ),
        );

    return PlannerPage(
      activeMonth: date.month,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: daysFullEn[di],
          subEn: '${date.day} ${monthsEn[date.month - 1].toUpperCase()} $planYear',
          titleAr: daysAr[di],
          subAr: '${toArabicDigits(date.day)} ${monthsAr[date.month - 1]} ${toArabicDigits(planYear)}',
          titleSize: 36,
        ),
        if (hol.isNotEmpty || evs.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final h in hol)
            _Chip(
                en: h.provisional ? '${h.en} *' : h.en,
                ar: h.ar,
                color: C.holiday,
                label: 'PUBLIC HOLIDAY · عطلة رسمية'),
          for (final e in evs) _Chip(en: e.en, ar: e.ar, color: C.gold, label: 'EVENT'),
          if (hol.any((h) => h.provisional))
            Text('* Date provisional until confirmed by the Government.',
                style: T.sans(9.5, color: C.navy.withValues(alpha: .55))),
        ],
        label('PRIORITIES', 'الأولويات'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.input.withValues(alpha: .35),
              border: Border.all(color: C.line, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: store.flag('dvf:$k:$i'),
                        onChanged: (v) => store.setFlag('dvf:$k:$i', v ?? false),
                        side: const BorderSide(color: C.gold, width: 1.5),
                        activeColor: C.gold,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: EditableBox(storeKey: 'dv:$k:p$i', style: T.sans(12))),
                  ]),
                ),
            ]),
          ),
        ),
        label('SCHEDULE', 'الجدول'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [
            for (var h = firstHour; h <= lastHour; h++)
              // Min-height, not a fixed 46: rows must grow with system text
              // scale instead of clipping the note field.
              Container(
                constraints: const BoxConstraints(minHeight: 46),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: .8))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 54,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${h.toString().padLeft(2, '0')}:00',
                          style: T.sans(11, color: weekend ? C.gold : C.navy, w: FontWeight.w700)),
                    ),
                  ),
                  Expanded(
                    child: EditableBox(
                      storeKey: 'dv:$k:h$h',
                      style: T.sans(12),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
        label('NOTES', 'ملاحظات'),
        // Same key as the month-view cell and the week-view row, so all stay in sync.
        EditableBox(
          storeKey: 'day:$k',
          minLines: 5,
          maxLines: 10,
          style: T.sans(13),
          padding: const EdgeInsets.all(10),
        ),
        label('ONE ARABIC WORD TODAY', 'كلمة عربية اليوم'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.input.withValues(alpha: .35),
              border: Border.all(color: C.line, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Expanded(
                child: EditableBox(
                  storeKey: 'dv:$k:word',
                  textDirection: TextDirection.rtl,
                  style: T.ar(18),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              HabitDot(storeKey: habitKey(date), label: '✓', size: 34),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        WordCard(month: date.month, compact: true),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.en, required this.ar, required this.color, required this.label});
  final String en, ar, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: T.sans(8.5, color: color, w: FontWeight.w700, spacing: 1.5)),
                Text(en, style: T.sans(13, w: FontWeight.w700)),
              ]),
            ),
            Text(ar, textDirection: TextDirection.rtl, style: T.ar(14, color: color)),
          ]),
        ),
      );
}
