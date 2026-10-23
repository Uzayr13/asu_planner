import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/holidays.dart';
import '../theme.dart';

/// Card listing public holidays (and ASU events) for one month, or the whole year.
class HolidayList extends StatelessWidget {
  const HolidayList({super.key, this.month, this.showEvents = true});
  final int? month; // null = whole year
  final bool showEvents;

  @override
  Widget build(BuildContext context) {
    final hs = month == null ? holidays : holidaysInMonth(month!);
    final es = !showEvents
        ? <PlannerEvent>[]
        : events.where((e) => month == null || e.date.month == month).toList();
    if (hs.isEmpty && es.isEmpty) return const SizedBox.shrink();

    // merge by date
    final rows = <({DateTime date, String en, String ar, Color color, bool prov})>[
      for (final h in hs) (date: h.date, en: h.en, ar: h.ar, color: C.holiday, prov: h.provisional),
      for (final e in es) (date: e.date, en: e.en, ar: e.ar, color: C.gold, prov: false),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final anyProv = rows.any((r) => r.prov);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.input.withValues(alpha: .35),
          border: Border.all(color: C.line, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(month == null ? 'PUBLIC HOLIDAYS 2027' : 'PUBLIC HOLIDAYS',
                  style: T.sans(10.5, color: C.holiday, w: FontWeight.w700, spacing: 2)),
            ),
            // Align keeps the Arabic on the right edge. Flexible alone made it
            // a flex child sitting at the left of its share, so it floated in
            // the middle of the card.
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('العطل الرسمية',
                    textDirection: TextDirection.rtl, style: T.ar(13, color: C.holiday)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              // The Arabic holiday name is the long one and used to have no
              // flex at all, pushing the row 23-48px past its edge. Give it
              // and the English name room to wrap instead.
              child: Row(children: [
                Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 62,
                  child: Text(
                      '${daysFullEn[r.date.weekday - 1].substring(0, 3)} ${r.date.day} ${monthsEn[r.date.month - 1].substring(0, 3)}',
                      style: T.sans(11.5, w: FontWeight.w700)),
                ),
                Expanded(
                  child: Text('${r.en}${r.prov ? ' *' : ''}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: T.sans(12)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(r.ar,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: T.ar(12.5, color: r.color)),
                  ),
                ),
              ]),
            ),
          if (anyProv) ...[
            const SizedBox(height: 6),
            Text('* Date provisional until confirmed by the Government.',
                style: T.sans(9.5, color: C.navy.withValues(alpha: .55))),
          ],
        ]),
      ),
    );
  }
}

/// Small coloured label shown inside a day cell/row for a holiday or event.
class DayMark extends StatelessWidget {
  const DayMark({super.key, required this.text, required this.color, this.size = 8.5});
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: T.sans(size, color: color, w: FontWeight.w700));
}
