import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/layout.dart';
import '../theme.dart';

/// Page 1. Drawn entirely in code (no image assets needed).
///
/// Layout is a Column of spacers rather than absolutely positioned blocks: at
/// phone-landscape heights the old `Alignment(0, -0.35)` pushed the 210pt
/// emblem off the top and stacked the title, tap hint and footer on top of
/// each other. Spacing here is derived from [L] so the block scales down on
/// short viewports instead of overflowing.
class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return SizedBox.expand(
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _CoverPainter())),
        // Positioned.fill, not a bare SafeArea: a non-positioned Stack child
        // is sized to its intrinsic width and aligned topStart, which shoved
        // the whole hero block against the left edge.
        Positioned.fill(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, c) {
            // Short or wide viewports (phone landscape) need a smaller emblem
            // and tighter gaps or the stack still runs past the fold.
            final short = l.isShort || c.maxHeight < 520;
            final emblem =
                (short ? c.maxHeight * .32 : c.maxHeight * .34).clamp(88.0, 210.0);

            return Column(children: [
              const Spacer(flex: 2),
              // Flexible, not bare: a non-flex Column child gets unbounded
              // height, so this FittedBox had nothing to shrink to and the
              // cover overflowed the bottom at 2x text on short viewports.
              Flexible(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: emblem,
                      height: emblem,
                      child: Stack(alignment: Alignment.center, children: [
                        CustomPaint(
                            size: Size.square(emblem), painter: EmblemPainter()),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('٢٠٢٧',
                              style: T.arDisplay(52, color: C.goldBright)),
                        ),
                      ]),
                    ),
                  SizedBox(height: short ? l.gapL : l.gapXl + G.s),
                  Text('يَوْمي',
                      textDirection: TextDirection.rtl,
                      style: T.arDisplay(46, color: C.silver)),
                  SizedBox(height: l.gapS),
                  Text('DIGITAL PLANNER 2027',
                      style: T.sans(16,
                          color: C.goldBright,
                          w: FontWeight.w700,
                          spacing: 5)),
                  SizedBox(height: l.gapS),
                  Text('Arabic · English',
                      style: T.sans(12, color: Colors.white54, spacing: 2)),
                  ]),
                ),
              ),
              const Spacer(flex: 2),
              // Hint and footer are chrome, not content: clamp their text
              // scale so 2x accessibility text cannot outgrow the spacer
              // layout on short viewports.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.4,
                child: Column(children: [
                  Text('TAP TO OPEN · اضغط للفتح',
                      style: T.sans(11,
                          color: C.goldBright, w: FontWeight.w700, spacing: 2)),
                  SizedBox(height: l.gapM),
                  Column(children: [
                    Text('اتحاد متحدثي اللغة العربية - موريشيوس',
                        textDirection: TextDirection.rtl,
                        style: T.ar(17, color: Colors.white70)),
                    SizedBox(height: l.gapS),
                    Text('ARABIC SPEAKING UNION - MAURITIUS',
                        style: T.sans(10.5, color: Colors.white54, spacing: 3)),
                  ]),
                  SizedBox(height: l.gapL),
                ]),
              ),
            ]);
            }),
          ),
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

    // Every vertical offset is a fraction of mh, not an absolute pixel: a
    // 375pt-tall landscape window must not stretch the scene past its edge.
    final mh = math.min(s.width, s.height);

    // Faint star pattern in the top ~60%
    final p = Paint()
      ..color = C.goldBright.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final step = math.max(36.0, mh / 7);
    final starR = step * .25;
    for (var y = step * .35; y < s.height * .6; y += step) {
      for (var x = step * .35; x < s.width + step; x += step) {
        _star(canvas, Offset(x, y), starR, p);
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
    final waveGap = math.max(10.0, mh / 28);
    for (var i = 0; i < 5; i++) {
      final y = seaTop + waveGap + i * waveGap;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= s.width; x += 4) {
        path.lineTo(x, y + math.sin(x / 26 + i) * 5);
      }
      canvas.drawPath(path, wave);
    }

    // Mountain silhouette
    final m = Path()
      ..moveTo(0, seaTop)
      ..lineTo(s.width * .15, seaTop - mh * .04)
      ..lineTo(s.width * .32, seaTop - mh * .16)
      ..lineTo(s.width * .45, seaTop - mh * .30)
      ..lineTo(s.width * .60, seaTop - mh * .30)
      ..lineTo(s.width * .72, seaTop - mh * .16)
      ..lineTo(s.width * .85, seaTop - mh * .065)
      ..lineTo(s.width, seaTop)
      ..close();
    canvas.drawPath(m, Paint()..color = const Color(0xFF080F1C));

    // Sun / moon
    final r = mh * .13;
    final c = Offset(s.width * .76, seaTop - r * 2);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.goldBright, Color(0xFF7A5F28)])
              .createShader(Rect.fromCircle(center: c, radius: r)));
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

class EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final p = Paint()
      ..color = C.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s.width / 95);
    canvas.drawRect(Rect.fromCenter(center: c, width: s.width * .72, height: s.width * .72), p);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s.width * .72, height: s.width * .72), p);
    canvas.restore();
    canvas.drawCircle(c, s.width * .32, p);
    canvas.drawCircle(c, s.width * .30, p..strokeWidth = math.max(.6, s.width / 200));
  }

  @override
  bool shouldRepaint(_) => false;
}
