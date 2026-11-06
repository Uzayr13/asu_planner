import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the recording for one of the scheduled words.
///
/// Recordings are looked up by **slot index**, not month — the vocabulary runs
/// 25 words from 18 Dec 2026, so `01.mp3` (the launch word) … `25.mp3`. See
/// `lib/data/content.dart` for what each slot contains.
///
/// Extensions are probed in order; the first hit wins. If no file is there yet
/// [toggle] returns false so the UI can say "recording coming soon" instead of
/// failing.
class WordAudio {
  WordAudio._();

  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<int?> playing = ValueNotifier<int?>(null); // slot or null
  static bool _wired = false;
  static const _exts = ['mp3', 'm4a', 'wav', 'ogg', 'aac'];

  /// `audio/words/01` … `audio/words/25`. Two digits covers the whole schedule.
  static String _base(int index) => 'audio/words/${index.toString().padLeft(2, '0')}';

  static Future<String?> _find(int index) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets().toSet();
    for (final e in _exts) {
      final p = '${_base(index)}.$e';
      if (all.contains('assets/$p')) return p; // AssetSource is relative to assets/
    }
    return null;
  }

  static Future<bool> hasRecording(int index) async => (await _find(index)) != null;

  /// Play, or stop if this slot's word is already playing.
  /// Returns false when there is no recording for [index] yet.
  static Future<bool> toggle(int index) async {
    if (!_wired) {
      _player.onPlayerComplete.listen((_) => playing.value = null);
      _wired = true;
    }
    if (playing.value == index) {
      await _player.stop();
      playing.value = null;
      return true;
    }
    final path = await _find(index);
    if (path == null) return false;
    await _player.stop();
    playing.value = index;
    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      playing.value = null;
      return false;
    }
    return true;
  }
}
