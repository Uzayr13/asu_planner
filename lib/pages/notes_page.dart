import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Pages 68-69. Ruled free-writing pages; each line is its own saved field.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key, required this.index});
  final int index; // 1-based

  static const lines = 20;

  @override
  Widget build(BuildContext context) {
    return PlannerPage(
      activeMonth: null,
      tabsOpenMonthView: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          titleEn: 'Notes',
          subEn: 'PAGE $index',
          titleAr: 'ملاحظات',
          subAr: '$index'.split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join(),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < lines; i++)
          // Min-height, not a fixed 40: ruled lines grow with system text scale.
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: .8))),
            child: EditableBox(
              storeKey: 'note:$index:$i',
              style: T.sans(14),
              padding: const EdgeInsets.only(top: 10),
            ),
          ),
      ]),
    );
  }
}

/// NOTES VIEW: swipe between note pages.
class NotesView extends StatelessWidget {
  const NotesView({super.key});
  @override
  Widget build(BuildContext context) => PageView.builder(
        itemCount: 2,
        itemBuilder: (_, i) => ColoredBox(
          color: C.paper,
          child: SingleChildScrollView(child: NotesPage(index: i + 1)),
        ),
      );
}
