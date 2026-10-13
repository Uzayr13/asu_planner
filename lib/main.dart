import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/cover_page.dart';
import 'pages/day_page.dart';
import 'pages/month_page.dart';
import 'pages/notes_page.dart';
import 'pages/week_page.dart';
import 'pages/words_page.dart';
import 'pages/year_page.dart';
import 'store.dart';
import 'theme.dart';
import 'layout/layout.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  runApp(PlannerApp(store: store));
}

class PlannerApp extends StatefulWidget {
  const PlannerApp({super.key, required this.store});
  final Store store;

  @override
  State<PlannerApp> createState() => _PlannerAppState();
}

class _PlannerAppState extends State<PlannerApp> {
  final _app = AppState();

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScope(
        store: widget.store,
        child: AppScope(
          app: _app,
          child: MaterialApp(
            title: 'المفكرة الرقمية · Digital Planner 2027',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            // Single choke point for the width-based type scale: every T.*
            // style scales without its call site knowing about layout.
            builder: (context, child) => TypeScale(child: child ?? const SizedBox.shrink()),
            // UI chrome is LTR; Arabic strings set their own RTL direction.
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PlannerScreen(),
          ),
        ),
      );
}

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // Cover: tap anywhere to open the planner.
    if (!app.opened) {
      return Scaffold(
        body: GestureDetector(
          onTap: app.open,
          child: Stack(children: [
            const CoverPage(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 110,
              child: Center(
                child: Text('TAP TO OPEN · اضغط للفتح',
                    style: T.sans(11, color: C.goldBright, w: FontWeight.w700, spacing: 2)),
              ),
            ),
          ]),
        ),
      );
    }

    final Widget body = switch (app.view) {
      ViewMode.year => const _Scroll(child: YearPage()),
      ViewMode.month => const MonthView(),
      ViewMode.week => const WeekView(),
      ViewMode.day => const DayView(),
      ViewMode.notes => const NotesView(),
      ViewMode.words => const _Scroll(child: WordsPage()),
    };

    return Scaffold(
      backgroundColor: C.paper,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: body),
        ),
      ),
      bottomNavigationBar: const _ViewBar(),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: C.paper, child: SingleChildScrollView(child: child));
}

/// Bottom bar: Year · Month · Week · Day · Notes · Words
class _ViewBar extends StatelessWidget {
  const _ViewBar();

  static const _items = <(ViewMode, IconData, String, String)>[
    (ViewMode.year, Icons.grid_view_rounded, 'Year', 'السنة'),
    (ViewMode.month, Icons.calendar_month_rounded, 'Month', 'الشهر'),
    (ViewMode.week, Icons.view_week_rounded, 'Week', 'الأسبوع'),
    (ViewMode.day, Icons.today_rounded, 'Day', 'اليوم'),
    (ViewMode.notes, Icons.edit_note_rounded, 'Notes', 'ملاحظات'),
    (ViewMode.words, Icons.translate_rounded, 'Words', 'كلماتي'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Container(
      color: C.navy,
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            for (final (mode, icon, en, ar) in _items)
              Expanded(
                child: InkWell(
                  onTap: () => app.show(mode),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // Chrome must not blow up with accessibility text scale —
                    // clamp it so the six tabs always fit the bar.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.4,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon,
                            size: 22, color: app.view == mode ? C.goldBright : Colors.white54),
                        const SizedBox(height: 2),
                        Text(en,
                            style: T.sans(10,
                                color: app.view == mode ? C.goldBright : Colors.white70,
                                w: FontWeight.w700)),
                        Text(ar,
                            textDirection: TextDirection.rtl,
                            style: T.ar(9.5,
                                color: app.view == mode ? C.goldBright : Colors.white54)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
