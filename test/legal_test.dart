import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asu_planner/pages/legal.dart';
import 'package:asu_planner/pages/settings_sheet.dart';
import 'package:asu_planner/store.dart';
import 'package:asu_planner/version.dart';
import 'package:asu_planner/widgets/common.dart';

/// Widget tests for the privacy & terms and licences notices.
///
/// These are static text surfaces, so the assertions pin the copy that must
/// never silently drift: the update-check disclosure, the unencrypted-backup
/// warning, the contact address, and the licences the terms point at.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'ui:noticeSeen': true});
  });

  Future<void> openDialog(WidgetTester tester, void Function(BuildContext) show) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => show(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('privacy & terms shows both sections and the key notices', (tester) async {
    await openDialog(tester, LegalNotice.showPrivacyTerms);

    expect(find.text('Privacy & terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    // The three lines that must never drift: the update-check disclosure,
    // the unencrypted-backup warning, and the contact address.
    expect(find.textContaining('checks GitHub for updates'), findsOneWidget);
    expect(find.textContaining('not encrypted'), findsOneWidget);
    expect(find.textContaining('uzayr1309@gmail.com'), findsOneWidget);
    expect(find.textContaining('as is'), findsOneWidget);
    expect(find.textContaining('provisional (moon sighting)'), findsOneWidget);
  });

  testWidgets('licences dialog lists the fonts and the software', (tester) async {
    await openDialog(tester, LegalNotice.showLicences);

    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.textContaining('SIL Open Font License 1.1'), findsOneWidget);
    expect(find.textContaining('Playfair Display'), findsOneWidget);
    expect(find.textContaining('Lato'), findsOneWidget);
    expect(find.textContaining('Amiri'), findsOneWidget);
    expect(find.textContaining('Noto Naskh Arabic'), findsOneWidget);
    expect(find.textContaining('BSD-3-Clause'), findsNWidgets(2));
    expect(find.textContaining('MIT'), findsOneWidget);
    expect(find.textContaining('LICENSES/'), findsOneWidget);
  });

  testWidgets('settings sheet shows the legal rows and the version', (tester) async {
    final store = await Store.open();
    await tester.pumpWidget(StoreScope(
      store: store,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SettingsSheet.open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy & terms'), findsOneWidget);
    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.text('Version $kAppVersion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
