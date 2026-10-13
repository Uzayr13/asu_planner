import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the recording for a month's word.
///
/// Recordings are looked up by month number in `assets/audio/words/`:
///   01.mp3 (January) ... 12.mp3 (December). m4a / wav / ogg / aac also work.
/// If a file isn't there yet, [toggle] returns false so the UI can say
/// "recording coming soon" instead of failing.
class WordAudio {
  WordAudio._();

  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<int?> playing = ValueNotifier<int?>(null); // month or null
  static bool _wired = false;
  static const _exts = ['mp3', 'm4a', 'wav', 'ogg', 'aac'];

  static String _base(int month) => 'audio/words/${month.toString().padLeft(2, '0')}';

  static Future<String?> _find(int month) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets().toSet();
    for (final e in _exts) {
      final p = '${_base(month)}.$e';
      if (all.contains('assets/$p')) return p; // AssetSource is relative to assets/
    }
    return null;
  }

  static Future<bool> hasRecording(int month) async => (await _find(month)) != null;

  /// Play, or stop if this month's word is already playing.
  /// Returns false when there is no recording for [month] yet.
  static Future<bool> toggle(int month) async {
    if (!_wired) {
      _player.onPlayerComplete.listen((_) => playing.value = null);
      _wired = true;
    }
    if (playing.value == month) {
      await _player.stop();
      playing.value = null;
      return true;
    }
    final path = await _find(month);
    if (path == null) return false;
    await _player.stop();
    playing.value = month;
    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      playing.value = null;
      return false;
    }
    return true;
  }
}
