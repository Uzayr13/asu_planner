import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asu_planner/main.dart';
import 'package:asu_planner/store.dart';

/// Layout smoke tests.
///
/// There are no pixel assertions here and there cannot be: the UI renders to
/// canvas. What these do catch is the failure mode that matters most — a
/// RenderFlex overflow, which throws in tests and would paint the yellow/black
/// stripes on a real device. Every page is exercised at every breakpoint band
/// and at accessibility text scales.
void main() {
  setUp(() {
    // No network in tests: without this google_fonts hangs or throws.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Pre-dismiss the first-visit notice. It is a modal dialog over the whole
    // scaffold, so with it open the bottom-bar taps below would hit the barrier
    // and pass only incidentally.
    SharedPreferences.setMockInitialValues({'ui:noticeSeen': true});
  });

  const sizes = <(String, double, double)>[
    ('tiny-phone', 320, 568),
    ('phone', 375, 667),
    ('landscape', 667, 375),
    ('wide-short', 844, 390),
    ('tablet', 768, 1024),
    ('desktop', 1280, 800),
  ];

  const scales = <double>[1.0, 1.5, 2.0];

  // Bottom bar order in main.dart `_items`.
  const viewLabels = ['Year', 'Month', 'Week', 'Day', 'Notes', 'Words'];

  for (final (name, w, h) in sizes) {
    for (final scale in scales) {
      testWidgets('$name ${w}x$h @ ${scale}x text', (tester) async {
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        // Capture the full FlutterErrorDetails — the widget path lives there,
        // not on the exception itself.
        final problems = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          problems.add(details.toDiagnosticsNode().toStringDeep());
          previous?.call(details);
        };
        addTearDown(() => FlutterError.onError = previous);

        final store = await Store.open();
        await tester.pumpWidget(PlannerApp(store: store));
        await tester.pumpAndSettle();

        // Cover is a full-screen tap target.
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'cover opened');

        for (final label in viewLabels) {
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle();
          final e = tester.takeException();
          if (e != null) {
            fail('view: $label\n${problems.join('\n----\n')}\n$e');
          }
        }
      });
    }
  }
}
