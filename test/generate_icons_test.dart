import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asu_planner/pages/cover_page.dart';
import 'package:asu_planner/theme.dart';

/// Generates the app icon set from the cover emblem.
///
/// Not part of the normal suite — it writes files. Run it explicitly:
///
///   GENERATE_ICONS=true flutter test test/generate_icons_test.dart
///
/// Keeping the generator in the repo is what makes the icons reproducible if
/// the emblem ever changes. The ground is [C.navy] so the gold emblem reads on
/// any wallpaper, and the same drawing serves as the maskable variant because
/// the emblem already sits inside the ~80% safe zone.
void main() {
  final enabled = Platform.environment['GENERATE_ICONS'] == 'true';

  testWidgets('generate icons', (tester) async {
    Future<Uint8List> render(int size, {double inset = 0.85}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final side = size.toDouble();
      canvas.drawRect(Offset.zero & Size(side, side), Paint()..color = C.navy);
      // The emblem's rotated square reaches slightly past its own bounding box,
      // so painting it full-bleed clips the diamond tips. Maskable icons are
      // cropped to a circle and need the full ~80% safe zone; ordinary ones can
      // use a little more presence.
      final safe = side * inset;
      canvas.translate((side - safe) / 2, (side - safe) / 2);
      EmblemPainter().paint(canvas, Size(safe, safe));
      final image = await recorder.endRecording().toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    }

    // toImage() is real async work, and the test binding runs in a fake async
    // zone where awaiting it hangs forever. runAsync gives us a real one.
    await tester.runAsync(() async {
      final root = Directory.current.path;
      final webIcons = Directory('$root/web/icons')..createSync(recursive: true);

      // Web icons. Names kept as-is so manifest.json needs no edit. Maskable
      // variants get the tighter inset so a circular crop cannot clip them.
      const webIconsList = <(String, int, double)>[
        ('Icon-192.png', 192, 0.85),
        ('Icon-512.png', 512, 0.85),
        ('Icon-maskable-192.png', 192, 0.72),
        ('Icon-maskable-512.png', 512, 0.72),
      ];
      for (final (name, size, inset) in webIconsList) {
        File('${webIcons.path}/$name')
            .writeAsBytesSync(await render(size, inset: inset));
      }
      File('$root/web/favicon.png').writeAsBytesSync(await render(48));

      // Android launcher icons, one per density bucket.
      const mipmaps = <(String, int)>[
        ('mipmap-mdpi', 48),
        ('mipmap-hdpi', 72),
        ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144),
        ('mipmap-xxxhdpi', 192),
      ];
      for (final (dir, size) in mipmaps) {
        final path = '$root/android/app/src/main/res/$dir';
        Directory(path).createSync(recursive: true);
        File('$path/ic_launcher.png').writeAsBytesSync(await render(size));
      }

      // Windows: one .ico holding a PNG per size Windows asks for.
      const icoSizes = [16, 32, 48, 64, 128, 256];
      final pngs = [for (final s in icoSizes) await render(s)];
      File('$root/windows/runner/resources/app_icon.ico')
          .writeAsBytesSync(buildIco(icoSizes, pngs));
    });
  }, skip: !enabled);
}

/// Minimal ICO writer. Each entry is a PNG — supported since Windows Vista and
/// far simpler than embedding raw BMPs.
///
/// All multi-byte fields are little-endian. Width and height are one byte
/// each, where 0 means 256.
Uint8List buildIco(List<int> sizes, List<Uint8List> pngs) {
  final count = sizes.length;
  var offset = 6 + 16 * count;

  final header = ByteData(6)
    ..setUint16(0, 0, Endian.little) // reserved
    ..setUint16(2, 1, Endian.little) // type: icon
    ..setUint16(4, count, Endian.little);
  final out = BytesBuilder()..add(header.buffer.asUint8List());

  for (var i = 0; i < count; i++) {
    final png = pngs[i];
    final s = sizes[i];
    final entry = ByteData(16)
      ..setUint8(0, s >= 256 ? 0 : s)
      ..setUint8(1, s >= 256 ? 0 : s)
      ..setUint8(2, 0) // colour palette
      ..setUint8(3, 0) // reserved
      ..setUint16(4, 1, Endian.little) // colour planes
      ..setUint16(6, 32, Endian.little) // bits per pixel
      ..setUint32(8, png.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    out.add(entry.buffer.asUint8List());
    offset += png.length;
  }

  for (final png in pngs) {
    out.add(png);
  }
  return out.toBytes();
}
