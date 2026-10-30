import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../layout/layout.dart';
import '../theme.dart';
import '../update_check.dart';
import '../update_check_io.dart';
import '../version.dart';

/// A slim bar shown when a newer build exists.
///
/// Updates do not reach anyone automatically today: the web app refreshes in
/// the background but a page already open keeps running old code, and the APK
/// and Windows zip never update themselves. This is the thing that says so.
///
/// **The button differs by platform.** On web it reloads in place — the
/// service worker already has the new build cached, so one reload and the user
/// is current. On native it opens the release page, where the new download is.
///
/// `kIsWeb` is the right tool here and is deliberately the only place it is
/// used: `defaultTargetPlatform` cannot tell a Mac browser from a native macOS
/// build, and the action genuinely differs between them.
///
/// Dismissal is per-session and in memory only. No `ui:` flag, so nothing new
/// travels in a backup — and the banner comes back next launch, because the
/// update is still there.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key, this.checkForUpdate});

  /// How to learn about a newer release. Injectable so tests can force the
  /// banner on without touching the network; production uses
  /// [fetchNewerReleaseTag].
  final Future<String?> Function(String current)? checkForUpdate;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  /// The newer tag, once one has been found. Null while checking or when
  /// already current — the banner is absent in both cases.
  String? _newerTag;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final tag = await (widget.checkForUpdate ?? fetchNewerReleaseTag)(kAppVersion);
    // Belt and braces: the checker is supposed to return null when there is
    // nothing to do, but the banner verifies rather than trusts. A bad
    // response must never nag someone who is already up to date.
    if (!mounted || tag == null || !isNewerVersion(tag, kAppVersion)) return;
    setState(() => _newerTag = tag);
  }

  Future<void> _update() async {
    final messenger = ScaffoldMessenger.of(context);
    // webOnlyWindowName '_self' navigates this tab, which is exactly a reload:
    // the service worker serves the already-cached new build.
    final uri = kIsWeb
        ? Uri.base
        : Uri.parse('$_releasesBase/tag/${tagLabel(_newerTag!)}');
    final ok = await launchUrl(uri,
        webOnlyWindowName: kIsWeb ? '_self' : '_blank');
    if (!ok && mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Could not open the update · تعذر فتح التحديث'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  static const _releasesBase = 'https://github.com/Uzayr13/asu_planner/releases';

  @override
  Widget build(BuildContext context) {
    if (_newerTag == null || _dismissed) return const SizedBox.shrink();
    final l = L.of(context);

    return Material(
      color: C.navy,
      child: SafeArea(
        bottom: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: l.gapM, vertical: l.gapS),
            child: Row(children: [
              const Icon(Icons.system_update_alt_rounded, size: 18, color: C.goldBright),
              SizedBox(width: l.gapS),
              Expanded(
                child: Text('A new version is available · ${tagLabel(_newerTag!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.sans(12, color: Colors.white, w: FontWeight.w700)),
              ),
              TextButton(
                onPressed: _update,
                child: Text(kIsWeb ? 'Reload · إعادة' : 'Download · تحميل',
                    style: T.sans(12, color: C.goldBright, w: FontWeight.w700)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                tooltip: 'Dismiss',
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
