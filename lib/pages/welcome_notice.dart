import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../layout/layout.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Key under which "the user has seen and dismissed this" is stored.
/// Starts with [kUiKeyPrefix] so it never travels in a backup.
const String kUiNoticeSeenKey = 'ui:noticeSeen';

/// One-time first-visit notice.
///
/// Its real job is **preventing data loss on iOS**, not marketing. Safari
/// deletes website data after seven days without interaction, and only a
/// home-screen install is exempt. Someone who opens the URL in a tab and
/// starts typing notes will lose them. Nobody tells them, so this does.
///
/// Shown once after the cover opens, dismissed with one tap, and the
/// dismissal is remembered in `ui:noticeSeen`. Copy is platform-specific —
/// see [_copyFor].
class WelcomeNotice {
  const WelcomeNotice._();

  /// Show the notice if it has not been dismissed yet.
  ///
  /// Returns without doing anything when already seen. Must be called with a
  /// context that has both [StoreScope] and a [Navigator].
  static Future<void> maybeShow(BuildContext context) async {
    final store = StoreScope.of(context);
    if (store.flag(kUiNoticeSeenKey)) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const _WelcomeDialog(),
    );
  }

  /// Platform-specific headline, body and action label.
  static (String, String, String) _copyFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return (
          'Add to Home Screen',
          'Install this planner to your home screen — Share → Add to Home '
              'Screen. Safari clears website data after a week, so without '
              'this your notes are not safe here.',
          'Got it',
        );
      case TargetPlatform.android:
        return (
          'Use this as an app',
          'You can install this planner as an app, or keep using the browser. '
              'Either way your notes are stored on this device only.',
          'Got it',
        );
      default:
        return (
          'Your notes stay on this device',
          'Everything you write is kept on this device — there is no account '
              'and nothing is uploaded. Settings has an export if you want a '
              'copy.',
          'Got it',
        );
    }
  }
}

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final (title, body, action) = WelcomeNotice._copyFor(defaultTargetPlatform);
    final store = StoreScope.of(context);

    return AlertDialog(
      backgroundColor: C.paper,
      contentPadding: EdgeInsets.fromLTRB(l.gapL, l.gapL, l.gapL, l.gapS),
      actionsPadding: EdgeInsets.fromLTRB(l.gapL, 0, l.gapL, l.gapS),
      title: Text(title, style: T.sans(17, w: FontWeight.w700)),
      content: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(body, style: T.sans(13, color: C.navy.withValues(alpha: .85))),
            SizedBox(height: l.gapM),
            Text(_arabicFor(defaultTargetPlatform),
                textDirection: TextDirection.rtl,
                style: T.ar(12, color: C.navy.withValues(alpha: .7))),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Record before dismissing: if the write failed we would rather
            // show it again than silently lose the reminder.
            await store.setFlag(kUiNoticeSeenKey, true);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(action, style: T.sans(13, w: FontWeight.w700)),
        ),
      ],
    );
  }

  static String _arabicFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'أضِف التطبيق إلى الشاشة الرئيسية حتى تبقى ملاحظاتك محفوظة.';
      case TargetPlatform.android:
        return 'يمكنك تثبيت التطبيق أو استخدام المتصفح. ملاحظاتك محفوظة على هذا الجهاز.';
      default:
        return 'كل ما تكتبه محفوظ على هذا الجهاز فقط ولا يتم رفعه إلى الإنترنت.';
    }
  }
}
