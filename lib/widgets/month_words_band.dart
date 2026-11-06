import 'package:flutter/material.dart';

import '../data/calendar_math.dart' show planYear;
import '../data/content.dart';
import '../layout/layout.dart';
import '../theme.dart';
import 'common.dart';

/// Both words of a month, side by side, above the calendar grid.
///
/// The committee wanted both words visible at the top of the Month view and
/// explicitly *not* stacked one above the other, while still carrying the full
/// meaning and the French. Two columns answer that; the note clamps to two
/// lines with a tap to expand so the band stays readable at a glance.
///
/// Collapsible, because this is a lot of height to take from a calendar. The
/// choice persists per device in `ui:monthWordsCollapsed` — the reserved
/// prefix keeps it out of any backup, so it never travels with anyone's notes.
class MonthWordsBand extends StatelessWidget {
  const MonthWordsBand({super.key, required this.month, this.year = planYear});

  final int month;
  final int year;

  static const _collapseKey = 'ui:monthWordsCollapsed';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final store = StoreScope.of(context);
    final collapsed = store.flag(_collapseKey);
    final items = wordsInMonth(month, year: year);

    return Container(
      margin: EdgeInsets.only(bottom: l.gapM),
      padding: EdgeInsets.all(l.gapM),
      decoration: BoxDecoration(
        color: C.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text('WORDS OF THE MONTH · كلمات الشهر',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.sans(9,
                    color: C.goldBright, w: FontWeight.w700, spacing: 1.5)),
          ),
          InkWell(
            onTap: () => store.setFlag(_collapseKey, !collapsed),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                size: 18,
                color: C.goldBright,
              ),
            ),
          ),
        ]),
        SizedBox(height: l.gapS),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _WordColumn(word: items.isEmpty ? null : items.first, dense: collapsed)),
          Container(width: 1, color: C.gold.withValues(alpha: .35)),
          Expanded(
              child: _WordColumn(
                  word: items.length < 2 ? null : items.last, dense: collapsed)),
        ]),
      ]),
    );
  }
}

/// One half of the band. [dense] is the collapsed state — words and ranges
/// only, no French or note.
class _WordColumn extends StatelessWidget {
  const _WordColumn({required this.word, required this.dense});

  final Word? word;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final w = word;
    if (w == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: l.gapS),
        child: Text('—', style: T.sans(12, color: Colors.white38)),
      );
    }
    final index = words.indexOf(w) + 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: l.gapS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(w.rangeLabel,
            style: T.sans(9, color: C.goldBright, w: FontWeight.w700, spacing: 1.5)),
        SizedBox(height: dense ? 4 : 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Arabic gets the smaller share so the English meaning is never the
          // thing that truncates — at 320pt a wider word like "Lemon" was being
          // cut to "Lem…" because the two halves split the space evenly.
          Flexible(
            flex: 2,
            child: Text(w.ar,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.ar(dense ? 15 : 19, color: C.goldBright, w: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 3,
            child: Text(w.en,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.serif(dense ? 15 : 20, color: Colors.white)),
          ),
        ]),
        if (!dense) ...[
          const SizedBox(height: 4),
          Text(w.translit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.sans(10, color: Colors.white60)),
          const SizedBox(height: 4),
          Text('French: ${w.fr}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.sans(10, color: C.goldBright, w: FontWeight.w700)),
          const SizedBox(height: 6),
          _Note(text: w.noteEn),
          const SizedBox(height: 8),
          HearButton(index: index, compact: true),
        ],
      ]),
    );
  }
}

/// Two lines by default, tap for the rest. This is what lets the band carry
/// the full meaning without reading as cluttered.
class _Note extends StatefulWidget {
  const _Note({required this.text});
  final String text;

  @override
  State<_Note> createState() => _NoteState();
}

class _NoteState extends State<_Note> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      behavior: HitTestBehavior.opaque,
      child: Text(
        widget.text,
        maxLines: _open ? null : 2,
        overflow: _open ? null : TextOverflow.ellipsis,
        style: T.sans(9.5, color: Colors.white54),
      ),
    );
  }
}
