import 'package:flutter/material.dart';

import '../layout/layout.dart';
import '../theme.dart';

/// The privacy & terms notice and the open-source licences list.
///
/// Plain text in dialogs, opened from the two rows at the bottom of the
/// settings sheet. The copy is deliberately English-only for now — it is a
/// legal notice the committee wrote and reviewed in English; the Arabic
/// translation follows the same committee route as the holiday names.
///
/// Both dialogs follow the welcome-notice idiom: `AlertDialog` on `C.paper`,
/// content clamped to 1.4 text scale, and height-capped so the whole notice
/// stays scrollable on a 320x568 screen at 2.0x text scale.
class LegalNotice {
  const LegalNotice._();

  /// The privacy and terms of use notice.
  static Future<void> showPrivacyTerms(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const _PrivacyTermsDialog(),
      );

  /// What this app ships that belongs to other people, and under what terms.
  static Future<void> showLicences(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const _LicencesDialog(),
      );
}

/// Shared dialog shell: paper background, 1.4 text clamp, scrollable content
/// capped at 70% of the screen height so long text never overflows.
class _LegalDialog extends StatelessWidget {
  const _LegalDialog({required this.title, required this.sections, required this.footer});

  final String title;

  /// `(heading, paragraphs)` pairs, in order.
  final List<(String, List<String>)> sections;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      backgroundColor: C.paper,
      title: Text(title, style: T.sans(17, w: FontWeight.w700)),
      contentPadding: EdgeInsets.fromLTRB(l.gapL, 0, l.gapL, l.gapS),
      content: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: l.screenHeight * .7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (heading, paragraphs) in sections) ...[
                  Text(heading, style: T.sans(14.5, w: FontWeight.w700)),
                  SizedBox(height: l.gapXs),
                  for (final p in paragraphs)
                    Padding(
                      padding: EdgeInsets.only(bottom: l.gapS),
                      child: Text(p,
                          style: T.sans(12.5, color: C.navy.withValues(alpha: .85))),
                    ),
                  SizedBox(height: l.gapXs),
                ],
                if (footer != null)
                  Text(footer!,
                      style: T.sans(11.5, color: C.navy.withValues(alpha: .65))),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: T.sans(13, w: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _PrivacyTermsDialog extends StatelessWidget {
  const _PrivacyTermsDialog();

  @override
  Widget build(BuildContext context) => const _LegalDialog(
        title: 'Privacy & terms',
        sections: [
          (
            'Privacy',
            [
              'Yawmi stores everything you write - notes, priorities, habits '
                  'and settings - on your device only. There is no server and '
                  'no account, and nothing you write is sent to us or anyone '
                  'else. The app uses no analytics, advertising or tracking.',
              'To let you know when a new version is available, the app checks '
                  'GitHub for updates when it opens. This is a normal web '
                  'request - it reveals your IP address to GitHub, like any '
                  'page load - and carries nothing you write.',
              'The website that delivers the app may keep standard server logs '
                  '(such as IP address and time of visit) for security and '
                  'operation. We do not use these logs to identify you.',
              'Your notes stay on your device until you delete them, clear '
                  'your browser data or uninstall the app. Exported backups '
                  'are not encrypted: keep them somewhere safe and share them '
                  'only with people you trust.',
              'Contact: uzayr1309@gmail.com',
            ],
          ),
          (
            'Terms of use',
            [
              'The planner is provided free and as is, without warranties. '
                  'The Arabic Speaking Union is not liable for lost notes or '
                  'for decisions made using the planner.',
              'Public holiday dates are a guide only. Eid-Ul-Fitr is '
                  'provisional (moon sighting). Please check official sources.',
              'Notes are saved only on this device, so export a backup '
                  'regularly. On iPhone, iPad and Mac, add the app to your '
                  'Home Screen, or Safari may delete your data after seven '
                  'days without use.',
              'The content (word list, design, audio recordings, ASU name and '
                  'logo) belongs to the Arabic Speaking Union or its licensors. '
                  'It is for personal use only and may not be redistributed or '
                  'used commercially without permission.',
              'Open-source components are covered by their own licences '
                  '(see Open-source licences in Settings).',
              'We may update the app and these terms. The version number is '
                  'shown in Settings.',
            ],
          ),
        ],
        footer: null,
      );
}

class _LicencesDialog extends StatelessWidget {
  const _LicencesDialog();

  @override
  Widget build(BuildContext context) => const _LegalDialog(
        title: 'Open-source licences',
        sections: [
          (
            'Fonts - SIL Open Font License 1.1',
            [
              'Playfair Display - Copyright 2017 The Playfair Display Project '
                  'Authors, with Reserved Font Name "Playfair Display".',
              'Lato - Copyright 2011-2015 by tyPoland Lukasz Dziedzic, with '
                  'Reserved Font Name "Lato".',
              'Amiri - Copyright 2010-2022 The Amiri Project Authors.',
              'Noto Naskh Arabic - Copyright 2022 The Noto Project Authors.',
            ],
          ),
          (
            'Software',
            [
              'Flutter, flutter_localizations, shared_preferences, intl, '
                  'google_fonts, url_launcher, http, crypto - BSD-3-Clause '
                  '(Copyright The Flutter Authors and The Dart project authors).',
              'audioplayers, file_picker - MIT.',
              'Material icons and the CanvasKit renderer ship with Flutter '
                  '(Apache 2.0 / BSD-3-Clause).',
            ],
          ),
        ],
        footer: 'Full license texts ship in the LICENSES/ folder of the '
            'project repository, alongside the source.',
      );
}
