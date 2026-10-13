import 'package:flutter/material.dart';

import '../audio/word_audio.dart';
import '../data/calendar_math.dart';
import '../data/content.dart';
import '../layout/layout.dart';
import '../store.dart';
import '../theme.dart';

enum ViewMode { year, month, week, day, notes, words }

/// App-wide navigation state: which view is showing and which date is selected.
class AppState extends ChangeNotifier {
  AppState() {
    final n = DateTime.now();
    date = n.year == planYear ? DateTime(planYear, n.month, n.day) : DateTime(planYear, 1, 1);
  }

  bool opened = false; // cover shown until tapped
  ViewMode view = ViewMode.month;
  late DateTime date;

  void open() {
    opened = true;
    notifyListeners();
  }

  void show(ViewMode v) {
    view = v;
    notifyListeners();
  }

  void setDate(DateTime d) {
    if (d == date) return;
    date = d;
    notifyListeners();
  }

  void openDay(DateTime d) {
    date = d;
    view = ViewMode.day;
    notifyListeners();
  }

  /// Month tab tapped. Keeps the current view unless [switchToMonthView].
  void openMonth(int m, {bool switchToMonthView = false}) {
    if (date.month != m) date = DateTime(planYear, m, 1);
    if (switchToMonthView) view = ViewMode.month;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState app, required super.child}) : super(notifier: app);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class StoreScope extends InheritedNotifier<Store> {
  const StoreScope({super.key, required Store store, required super.child})
      : super(notifier: store);
  static Store of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// One planner page: month tabs on top, content, footer.
class PlannerPage extends StatelessWidget {
  const PlannerPage({
    super.key,
    required this.child,
    this.activeMonth,
    this.tabsOpenMonthView = false,
  });
  final Widget child;
  final int? activeMonth; // 1-12 or null
  final bool tabsOpenMonthView;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.paper,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MonthTabs(active: activeMonth, openMonthView: tabsOpenMonthView),
        const SizedBox(height: 20),
        child,
        const SizedBox(height: 16),
        const PageFooter(),
      ]),
    );
  }
}

class MonthTabs extends StatelessWidget {
  const MonthTabs({super.key, this.active, this.openMonthView = false});
  final int? active;
  final bool openMonthView;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = L.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: GestureDetector(
              onTap: () => app.openMonth(m, switchToMonthView: openMonthView),
              child: Container(
                constraints: const BoxConstraints(minHeight: 30),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: EdgeInsets.symmetric(vertical: l.gapXs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active == m ? C.navy : C.tab,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                // Twelve chips share one row: at 320pt or large text scale the
                // label would clip, so shrink it to the chip instead.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    monthsEn[m - 1].substring(0, 3).toUpperCase(),
                    style: T.sans(8.5,
                        color: active == m ? Colors.white : C.navy.withValues(alpha: .65),
                        w: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class PageFooter extends StatelessWidget {
  const PageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(
            child: Text('Swipe to turn the page',
                style: T.sans(10.5, color: C.gold, w: FontWeight.w700)),
          ),
          Flexible(
            child: Text('اتحاد متحدثي اللغة العربية - موريشيوس',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.ar(11, color: C.navy.withValues(alpha: .75))),
          ),
        ]),
      ),
    );
  }
}

/// English title (left) + Arabic title (right) + dotted gold rule.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.titleEn,
    required this.subEn,
    required this.titleAr,
    this.subAr,
    this.titleSize = 40,
  });
  final String titleEn, subEn, titleAr;
  final String? subAr;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    // On short viewports (phone landscape) a 40pt title eats most of the
    // visible height — shrink it there rather than crowding out the content.
    final size = L.of(context).titleSizeFor(titleSize);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // FittedBox: at 1.5x+ text scale a long weekday ("Wednesday")
              // at 36pt is wider than the column and overflowed it. Scale the
              // title to fit rather than clip it.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(titleEn, style: T.serif(size)),
              ),
              Text(subEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.sans(12, color: C.gold, w: FontWeight.w700, spacing: 3)),
            ]),
          ),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(titleAr,
                    textDirection: TextDirection.rtl, style: T.arDisplay(size * .95)),
              ),
              if (subAr != null)
                Text(subAr!, textDirection: TextDirection.rtl, style: T.ar(12, color: C.gold)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        const DottedRule(),
      ]),
    );
  }
}

class DottedRule extends StatelessWidget {
  const DottedRule({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final n = (c.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              n, (_) => Container(width: 5, height: 5, color: C.goldBright.withValues(alpha: .85))),
        );
      });
}

/// Tap-to-type field that autosaves to the Store on every change.
class EditableBox extends StatefulWidget {
  const EditableBox({
    super.key,
    required this.storeKey,
    this.minLines = 1,
    this.maxLines,
    this.style,
    this.textDirection,
    this.padding = const EdgeInsets.all(4),
    this.filled = true,
    this.enabled = true,
  });
  final String storeKey;
  final int minLines;
  final int? maxLines;
  final TextStyle? style;
  final TextDirection? textDirection;
  final EdgeInsets padding;
  final bool filled;
  final bool enabled;

  @override
  State<EditableBox> createState() => _EditableBoxState();
}

class _EditableBoxState extends State<EditableBox> {
  late final TextEditingController _c;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _c = TextEditingController(text: StoreScope.of(context).text(widget.storeKey));
      _init = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Container(
      color: widget.filled && widget.enabled ? C.input : null,
      padding: widget.padding,
      child: TextField(
        controller: _c,
        enabled: widget.enabled,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        textDirection: widget.textDirection,
        style: widget.style ?? T.sans(12),
        decoration: const InputDecoration(
            isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (v) => store.setText(widget.storeKey, v),
      ),
    );
  }
}

/// Navy rounded "Word of the month" card. [compact] = smaller variant.
class WordCard extends StatelessWidget {
  const WordCard({super.key, required this.month, this.compact = false});
  final int month;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = monthWords[month];
    final pad = compact ? 14.0 : 24.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(16)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WORD OF THE MONTH',
                  style: T.sans(10, color: C.goldBright, w: FontWeight.w700, spacing: 2)),
              const SizedBox(height: 6),
              if (w == null)
                Text('Coming soon', style: T.serif(compact ? 14 : 22, color: Colors.white54))
              else ...[
                Text(w.en, style: T.serif(compact ? 14 : 30, color: Colors.white)),
                Text(w.translit, style: T.sans(compact ? 10 : 12, color: Colors.white60)),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'French: ', style: T.sans(12, color: Colors.white70)),
                    TextSpan(text: w.fr, style: T.sans(12, color: Colors.white, w: FontWeight.w700)),
                  ])),
                  const SizedBox(height: 6),
                  Text(w.noteEn, style: T.sans(11, color: Colors.white54)),
                ],
                SizedBox(height: compact ? 8 : 14),
                HearButton(month: month, compact: compact),
              ],
            ]),
          ),
          if (w != null)
            // Flexible + FittedBox: the Arabic glyph is wide and has no flex of
            // its own, so at 320pt it used to push past the Row and overflow.
            // Scale it down to whatever width is left instead.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.ar,
                      textDirection: TextDirection.rtl,
                      style: T.arDisplay(compact ? 40 : 64, color: C.goldBright)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// "Hear now" pill. Plays assets/audio/words/<MM>.mp3; shows a friendly
/// message while the recording hasn't been added yet.
class HearButton extends StatelessWidget {
  const HearButton({super.key, required this.month, this.compact = false});
  final int month;
  final bool compact;

  Future<void> _tap(BuildContext context) async {
    final ok = await WordAudio.toggle(month);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Recording coming soon · التسجيل قريباً'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: WordAudio.playing,
      builder: (_, p, __) {
        final on = p == month;
        return GestureDetector(
          onTap: () => _tap(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 5 : 8),
            decoration: BoxDecoration(
              color: on ? C.goldBright : Colors.transparent,
              border: Border.all(color: C.goldBright, width: 1.3),
              borderRadius: BorderRadius.circular(30),
            ),
            // FittedBox: the pill has a natural width from icon + two labels
            // and used to overflow its column on narrow cards. Shrink it to
            // fit rather than push past the edge.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(on ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: compact ? 14 : 18, color: on ? C.navy : C.goldBright),
                const SizedBox(width: 6),
                Text(on ? 'Stop' : 'Hear now',
                    style: T.sans(compact ? 10 : 12,
                        color: on ? C.navy : C.goldBright, w: FontWeight.w700)),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text('استمع',
                      textDirection: TextDirection.rtl,
                      style: T.ar(12, color: on ? C.navy : C.goldBright, w: FontWeight.w700)),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Round M/T/W… toggle used by the "one Arabic word a day" tracker.
class HabitDot extends StatelessWidget {
  const HabitDot({super.key, required this.storeKey, required this.label, this.size = 30});
  final String storeKey;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final on = store.flag(storeKey);
    return GestureDetector(
      onTap: () => store.setFlag(storeKey, !on),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? C.gold : null,
          border: Border.all(color: C.gold, width: 1.5),
        ),
        child: Text(label,
            style: T.sans(10, color: on ? Colors.white : C.gold.withValues(alpha: .8), w: FontWeight.w700)),
      ),
    );
  }
}

String habitKey(DateTime d) => 'habit:${dateKey(mondayOf(d))}:${d.weekday - 1}';

/// Swipeable pages that stay in sync with AppState.date.
/// [indexOf] maps the selected date to a page; [onPage] maps a page back to a date.
class PagedView extends StatefulWidget {
  const PagedView({
    super.key,
    required this.count,
    required this.indexOf,
    required this.onPage,
    required this.builder,
  });
  final int count;
  final int Function(DateTime date) indexOf;
  final void Function(AppState app, int page) onPage;
  final Widget Function(int page) builder;

  @override
  State<PagedView> createState() => _PagedViewState();
}

class _PagedViewState extends State<PagedView> {
  PageController? _c;
  int _busy = 0; // >0 while a programmatic animation is running

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _sync(int target) async {
    final c = _c;
    if (c == null || !c.hasClients) return;
    if ((c.page ?? target.toDouble()).round() == target) return;
    _busy++;
    try {
      await c.animateToPage(target,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } finally {
      _busy--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final target = widget.indexOf(app.date).clamp(0, widget.count - 1);
    _c ??= PageController(initialPage: target);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync(target));
    return PageView.builder(
      controller: _c,
      itemCount: widget.count,
      onPageChanged: (i) {
        if (_busy == 0) widget.onPage(app, i);
      },
      itemBuilder: (_, i) => ColoredBox(
        color: C.paper,
        child: SingleChildScrollView(child: widget.builder(i)),
      ),
    );
  }
}
