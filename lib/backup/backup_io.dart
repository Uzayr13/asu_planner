import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// The thin platform edge for backup files — the only file in the app that
/// knows a picker exists. `backup.dart` and `store.dart` deal in `String` and
/// `Map`, so they stay pure and fully testable.
///
/// Cancellation is **not** an error: both calls return [BackupIoStatus.cancelled]
/// and the caller stays silent. A real failure — a write that did not happen, a
/// file that is not valid UTF-8 — returns [BackupIoStatus.failed] and the UI
/// turns that into the usual message.

enum BackupIoStatus { ok, cancelled, failed }

class BackupIoOutcome {
  const BackupIoOutcome(this.status, [this.text]);
  final BackupIoStatus status;

  /// File contents, present only when [status] is [BackupIoStatus.ok].
  final String? text;
}

class BackupIo {
  const BackupIo._();

  /// Ask the user where to save [jsonText], then write it.
  ///
  /// On web this is a browser download; on Android and Windows a native save
  /// dialog. Returns cancelled when the user backs out.
  static Future<BackupIoOutcome> saveBackup(String jsonText, String fileName) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(jsonText)),
        mimeType: 'application/json',
        dialogTitle: 'Save planner backup',
      );
      return uri == null
          ? const BackupIoOutcome(BackupIoStatus.cancelled)
          : const BackupIoOutcome(BackupIoStatus.ok);
    } catch (_) {
      return const BackupIoOutcome(BackupIoStatus.failed);
    }
  }

  /// Let the user pick a backup file and return its contents.
  ///
  /// The `.json` filter is a hint only — Android's document picker can still
  /// return anything, so `decodeBackup` is what actually rejects a bad file.
  static Future<BackupIoOutcome> openBackup() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Choose a planner backup',
      );
      if (file == null) return const BackupIoOutcome(BackupIoStatus.cancelled);
      final bytes = await file.readAsBytes();
      return BackupIoOutcome(BackupIoStatus.ok, utf8.decode(bytes));
    } catch (_) {
      return const BackupIoOutcome(BackupIoStatus.failed);
    }
  }
}
