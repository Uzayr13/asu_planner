import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:asu_planner/pages/update_banner.dart';

/// The banner is only useful if it appears when it should, stays away when it
/// should not, and never breaks the layout around it.
///
/// The checker is injected rather than mocked over the network: production
/// fetches GitHub, which must never be touched in tests.
void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpBanner(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets('appears when a newer release exists', (tester) async {
    await pumpBanner(tester, const UpdateBanner(checkForUpdate: _newer));
    expect(find.textContaining('A new version is available'), findsOneWidget);
    expect(find.textContaining('v99.0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays away when already current', (tester) async {
    await pumpBanner(tester, const UpdateBanner(checkForUpdate: _current));
    expect(find.textContaining('A new version is available'), findsNothing);
  });

  testWidgets('stays away when the check fails', (tester) async {
    await pumpBanner(tester, const UpdateBanner(checkForUpdate: _failed));
    expect(find.textContaining('A new version is available'), findsNothing,
        reason: 'a failed check must look exactly like "nothing to do"');
  });

  testWidgets('dismisses for the session', (tester) async {
    await pumpBanner(tester, const UpdateBanner(checkForUpdate: _newer));
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A new version is available'), findsNothing);
  });

  testWidgets('does not overflow at 320pt with 2x text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await pumpBanner(tester, const UpdateBanner(checkForUpdate: _newer));
    expect(find.textContaining('A new version is available'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'the banner shares the top of the screen with page content');
  });
}

Future<String?> _newer(String current) async => 'v99.0.0';
Future<String?> _current(String current) async => 'v$current';
Future<String?> _failed(String current) async => null;
