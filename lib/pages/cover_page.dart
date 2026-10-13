import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Page 1. Drawn entirely in code (no image assets needed).
class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _CoverPainter())),
        Align(
          alignment: const Alignment(0, -0.35),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 210,
              height: 210,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(210, 210), painter: _EmblemPainter()),
                Text('٢٠٢٧', style: T.arDisplay(52, color: C.goldBright)),
              ]),
            ),
            const SizedBox(height: 28),
            Text('المفكرة الرقمية',
                textDirection: TextDirection.rtl, style: T.arDisplay(46, color: C.silver)),
            const SizedBox(height: 6),
            Text('DIGITAL PLANNER 2027',
                style: T.sans(16, color: C.goldBright, w: FontWeight.w700, spacing: 5)),
            const SizedBox(height: 8),
            Text('Arabic · English',
                style: T.sans(12, color: Colors.white54, spacing: 2)),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Column(children: [
            Text('اتحاد متحدثي اللغة العربية - موريشيوس',
                textDirection: TextDirection.rtl, style: T.ar(17, color: Colors.white70)),
            const SizedBox(height: 6),
            Text('ARABIC SPEAKING UNION - MAURITIUS',
                style: T.sans(10.5, color: Colors.white54, spacing: 3)),
          ]),
        ),
      ]),
    );
  }
}

class _CoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    // Background
    canvas.drawRect(Offset.zero & s, Paint()..color = C.coverNavy);

    // Faint star pattern in the top ~60%
    final p = Paint()
      ..color = C.goldBright.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const step = 56.0;
    for (var y = 20.0; y < s.height * .6; y += step) {
      for (var x = 20.0; x < s.width + step; x += step) {
        _star(canvas, Offset(x, y), 14, p);
        canvas.drawCircle(Offset(x, y), 2, p..style = PaintingStyle.fill);
        p.style = PaintingStyle.stroke;
      }
    }

    // Sea
    final seaTop = s.height * .72;
    final seaRect = Rect.fromLTWH(0, seaTop, s.width, s.height - seaTop);
    canvas.drawRect(
        seaRect,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.tealTop, C.tealBottom])
              .createShader(seaRect));
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final y = seaTop + 24 + i * 22.0;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= s.width; x += 4) {
        path.lineTo(x, y + math.sin(x / 26 + i) * 5);
      }
      canvas.drawPath(path, wave);
    }

    // Mountain silhouette
    final m = Path()
      ..moveTo(0, seaTop)
      ..lineTo(s.width * .15, seaTop - 12)
      ..lineTo(s.width * .32, seaTop - 55)
      ..lineTo(s.width * .45, seaTop - 100)
      ..lineTo(s.width * .60, seaTop - 100)
      ..lineTo(s.width * .72, seaTop - 55)
      ..lineTo(s.width * .85, seaTop - 18)
      ..lineTo(s.width, seaTop)
      ..close();
    canvas.drawPath(m, Paint()..color = const Color(0xFF080F1C));

    // Sun / moon
    final c = Offset(s.width * .76, seaTop - 85);
    canvas.drawCircle(
        c,
        42,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.goldBright, Color(0xFF7A5F28)])
              .createShader(Rect.fromCircle(center: c, radius: 42)));
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final sq = Rect.fromCenter(center: o, width: r * 1.5, height: r * 1.5);
    c.drawRect(sq, p);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(math.pi / 4);
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.5), p);
    c.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final p = Paint()
      ..color = C.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRect(Rect.fromCenter(center: c, width: s.width * .72, height: s.width * .72), p);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s.width * .72, height: s.width * .72), p);
    canvas.restore();
    canvas.drawCircle(c, s.width * .32, p);
    canvas.drawCircle(c, s.width * .30, p..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_) => false;
}
