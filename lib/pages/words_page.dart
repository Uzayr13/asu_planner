import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Page 70. "Words I learned" vocabulary log (4 columns x 13 rows).
class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  static const rows = 13;
  static const headers = ['الكلمة', 'Meaning', 'Where I heard it', 'Date'];

  @override
  Widget build(BuildContext context) {
    return PlannerPage(
      activeMonth: null,
      tabsOpenMonthView: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHeader(
          titleEn: 'Words',
          subEn: 'I LEARNED IN 2027',
          titleAr: 'كلماتي',
          subAr: 'كلمات تعلّمتها',
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: C.line)),
            child: Column(children: [
              Container(
                color: C.navy,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      // Every label gets the same alignment and inset. The
                      // first column used to be right-aligned RTL while the
                      // rest were left-aligned LTR, so 'الكلمة' and 'Meaning'
                      // each sat hard against their shared boundary and read
                      // as one fused blob at every width.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(headers[i],
                            textAlign: TextAlign.center,
                            textDirection: i == 0 ? TextDirection.rtl : TextDirection.ltr,
                            style: i == 0
                                ? T.ar(13, color: Colors.white70, w: FontWeight.w700)
                                : T.sans(12, color: Colors.white70, w: FontWeight.w700, spacing: .5)),
                      ),
                    ),
                ]),
              ),
              for (var r = 0; r < rows; r++)
                // Min-height plus IntrinsicHeight: a vocab row must grow with
                // system text scale rather than clip the cell.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (var c = 0; c < 4; c++)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: C.line, width: .5)),
                            child: EditableBox(
                              storeKey: 'word:$r:$c',
                              maxLines: 2,
                              textDirection: c == 0 ? TextDirection.rtl : null,
                              style: c == 0 ? T.ar(15) : T.sans(11),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
