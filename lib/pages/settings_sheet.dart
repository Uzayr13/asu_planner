import 'package:flutter/material.dart';

import '../backup/backup.dart';
import '../backup/backup_io.dart';
import '../layout/layout.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Settings sheet: backup export, restore and the pre-import snapshot.
///
/// Opened from the gear on the bottom view bar. Follows the app's existing
/// conventions — bilingual EN/AR labels, the `L` layout tokens, the same 1.4
/// text-scale clamp the view bar uses, and the SnackBar idiom for results.
///
/// Every path that reports something **pops the sheet first**: a modal bottom
/// sheet sits over the Scaffold's SnackBar slot, so a message raised while it
/// is open is hidden behind it. The messenger is captured before popping.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  /// Open the sheet. Returns when it is dismissed.
  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: C.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const SettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final store = StoreScope.of(context);
    final notes = store.dump();
    final snapshotAt = store.snapshotCreatedAt();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(l.gapL, l.gapS, l.gapL, l.gapXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grabber
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: EdgeInsets.only(bottom: l.gapM),
                    decoration: BoxDecoration(
                      color: C.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text('Settings',
                          style: T.sans(18, w: FontWeight.w700)),
                    ),
                    Flexible(
                      child: Text('الإعدادات',
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.ar(15)),
                    ),
                  ],
                ),
                SizedBox(height: l.gapXs),
                Text('${notes.length} saved fields · عدد الحقول المحفوظة',
                    style: T.sans(11.5, color: C.navy.withValues(alpha: .7))),
                SizedBox(height: l.gapM),
                const Divider(height: 1, color: C.line),
                _ActionRow(
                  icon: Icons.save_alt_rounded,
                  en: 'Export my notes',
                  ar: 'نسخة احتياطية',
                  onTap: () => _export(context, store),
                ),
                _ActionRow(
                  icon: Icons.file_open_rounded,
                  en: 'Import from a file',
                  ar: 'استيراد نسخة',
                  onTap: () => _import(context, store),
                ),
                const Divider(height: 1, color: C.line),
                SizedBox(height: l.gapM),
                Text('Pre-import snapshot · النقطة قبل الاستيراد',
                    style: T.sans(11, color: C.navy.withValues(alpha: .65))),
                SizedBox(height: l.gapXs),
                Text(
                  snapshotAt == null
                      ? 'No snapshot yet · لا توجد نقطة بعد'
                      : 'Saved ${_stamp(snapshotAt)} · محفوظة',
                  style: T.sans(11, color: C.navy.withValues(alpha: .65)),
                ),
                SizedBox(height: l.gapS),
                _ActionButton(
                  label: 'Restore snapshot',
                  labelAr: 'استعادة',
                  enabled: snapshotAt != null,
                  onTap: () => _restore(context, store),
                ),
                SizedBox(height: l.gapM),
                const Divider(height: 1, color: C.line),
                SizedBox(height: l.gapM),
                Text(
                  'Importing merges the backup into this device; the backup wins on conflicts. '
                  'A snapshot of current notes is kept so a bad import can be undone. '
                  'Export before importing to keep a permanent copy.',
                  style: T.sans(11, color: C.navy.withValues(alpha: .65)),
                ),
                SizedBox(height: l.gapXs),
                Text(
                  'تتم دمج النسخة مع بيانات الجهاز وتُعتمد النسخة عند التعارض، '
                  'مع حفظ نقطة استعادة تلقائياً.',
                  textDirection: TextDirection.rtl,
                  style: T.ar(11, color: C.navy.withValues(alpha: .65)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // ---- flows ----------------------------------------------------------------

  static Future<void> _export(BuildContext context, Store store) async {
    final json = encodeBackup(store.dump());
    final result = await BackupIo.saveBackup(json, backupFileName());
    if (!context.mounted) return;
    _report(context, result.status,
        ok: 'Backup saved · تم حفظ النسخة',
        failed: 'Could not save the backup · تعذر حفظ النسخة');
  }

  static Future<void> _import(BuildContext context, Store store) async {
    final result = await BackupIo.openBackup();
    if (!context.mounted) return;
    switch (result.status) {
      case BackupIoStatus.cancelled:
        return; // stay on the sheet, say nothing
      case BackupIoStatus.failed:
        _report(context, result.status,
            failed: 'Could not read that file · تعذر قراءة الملف');
        return;
      case BackupIoStatus.ok:
        break;
    }

    final Backup incoming;
    try {
      incoming = decodeBackup(result.text!);
    } on BackupFormatException {
      if (!context.mounted) return;
      _report(context, BackupIoStatus.failed,
          failed: 'Not a valid backup file · ملف نسخة غير صالح');
      return;
    }

    // Offer the safety net and say what will change before touching anything.
    final proceed = await _confirmImport(context, store, incoming);
    if (proceed != true || !context.mounted) return;

    if (!await store.saveSnapshot()) {
      if (!context.mounted) return;
      _report(context, BackupIoStatus.failed,
          failed: 'Could not save a snapshot first · تعذر حفظ نقطة الاستعادة');
      return;
    }

    await store.applyAll(mergeNotes(store.dump(), incoming.notes));
    if (!context.mounted) return;
    _report(context, BackupIoStatus.ok, ok: 'Backup imported · تم استيراد النسخة');
  }

  static Future<void> _restore(BuildContext context, Store store) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await store.restoreSnapshot();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok
            ? 'Snapshot restored · تمت استعادة النقطة'
            : 'Could not restore · تعذر الاستعادة'),
        duration: const Duration(seconds: 2),
      ));
  }

  /// Show what an import would do, and offer to back up first.
  /// Returns true to proceed.
  static Future<bool?> _confirmImport(
      BuildContext context, Store store, Backup incoming) {
    final diff = diffNotes(store.dump(), incoming.notes);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.paper,
        title: const Text('Import this backup?'),
        content: Text(
          '${diff.summary}\n\n'
          'The backup wins where both have a note. A snapshot of your current '
          'notes is saved first so this can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await store.saveSnapshot();
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Save current notes first'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  /// Pop the sheet, then report. See the class doc for why the order matters.
  static void _report(BuildContext context, BackupIoStatus status,
      {String? ok, String? failed}) {
    final messenger = ScaffoldMessenger.of(context);
    final message = switch (status) {
      BackupIoStatus.ok => ok,
      BackupIoStatus.failed => failed,
      BackupIoStatus.cancelled => null,
    };
    Navigator.of(context).pop();
    if (message == null) return; // cancel: silent
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ));
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon,
      required this.en,
      required this.ar,
      required this.onTap});
  final IconData icon;
  final String en, ar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: l.gapM),
        child: Row(children: [
          Icon(icon, size: 22, color: C.gold),
          SizedBox(width: l.gapM),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(en,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.sans(13, w: FontWeight.w700)),
              Text(ar,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.ar(12)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label,
      required this.labelAr,
      required this.enabled,
      required this.onTap});
  final String label, labelAr;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final dim = C.navy.withValues(alpha: .3);
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: l.gapS, horizontal: l.gapM),
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? C.gold : dim),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$label · $labelAr',
            style: T.sans(12,
                color: enabled ? C.gold : dim, w: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
