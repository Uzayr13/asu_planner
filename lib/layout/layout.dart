import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Content column cap. Must match the `ConstrainedBox(maxWidth:)` in main.dart —
/// the planner stays a readable page-width on wide screens rather than a
/// stretched spreadsheet.
const double kContentMaxWidth = 820.0;

/// Vertical chrome the month grid shares with tabs, header, hint and footer.
const double kMonthChrome = 230.0;

/// Same, for short viewports (phone landscape) where the chrome is tighter.
const double kMonthChromeShort = 150.0;

/// Usable bounds for a month cell row height before text scaling.
const double kMinMonthCell = 56.0;
const double kMaxMonthCell = 110.0;

/// Width bands on the *content* column, not the raw screen.
enum WidthBand { xs, sm, md }

/// The one authority for layout math in this app.
///
/// Read once per build with `L.of(context)`. Everything that depends on screen
/// size — spacing, breakpoints, row heights, marker sizes — is derived here so
/// pages never scatter their own constants or `MediaQuery` lookups.
///
/// Note: viewport-derived math must come from [MediaQuery], never from a
/// `LayoutBuilder` height. Pages sit inside `SingleChildScrollView`, where
/// `LayoutBuilder` reports unbounded height and any division by it produces an
/// infinite or NaN size.
class L {
  L._(this.screenWidth, this.screenHeight, this.textScale);

  /// Builds the scale for the nearest [MediaQuery].
  ///
  /// Falls back to a 375x667 phone when there is no `MediaQuery` in scope (off
  /// the widget tree, or in a test that pumps a bare widget) so callers never
  /// have to null-check.
  factory L.of(BuildContext context) {
    final mq = MediaQuery.maybeOf(context) ??
        const MediaQueryData(size: Size(375, 667));
    return L._(mq.size.width, mq.size.height, mq.textScaler.scale(1.0));
  }

  final double screenWidth;
  final double screenHeight;

  /// Effective system text scale. 1.0 at default settings.
  final double textScale;

  /// The width the content column actually occupies.
  double get contentWidth => math.min(screenWidth, kContentMaxWidth);

  /// True for short viewports — phone landscape, a squashed desktop window.
  bool get isShort => screenHeight < 500;

  /// Width band on [contentWidth].
  WidthBand get band {
    final w = contentWidth;
    if (w < 360) return WidthBand.xs;
    if (w < 700) return WidthBand.sm;
    return WidthBand.md;
  }

  /// Gentle width-based type multiplier, applied once at the root by
  /// [TypeScale] so every `T.*` style scales without touching its call site.
  double get typeScale => switch (band) {
        WidthBand.xs => 0.92,
        WidthBand.sm => 1.0,
        WidthBand.md => 1.0,
      };

  /// Multiplies a spacing token. Tightens on short viewports and on `xs`.
  double sp(double base) =>
      base *
      (isShort ? 0.85 : 1.0) *
      switch (band) {
        WidthBand.xs => 0.9,
        WidthBand.sm => 1.0,
        WidthBand.md => 1.05,
      };

  double get gapXs => sp(G.xs);
  double get gapS => sp(G.s);
  double get gapM => sp(G.m);
  double get gapL => sp(G.l);
  double get gapXl => sp(G.xl);

  // ---- structure ----

  /// Mini-month columns in the Year view.
  ///
  /// Drops to 2 on `xs`: at 320pt with 3 columns a day cell is ~12pt wide,
  /// which cannot hold a readable marker. Fluid marker scaling alone is not
  /// enough there — the column count has to drop too.
  int get yearCols => switch (band) {
        WidthBand.xs => 2,
        WidthBand.sm => 3,
        WidthBand.md => 4,
      };

  /// Month grid row height so the calendar fits the viewport when it can.
  ///
  /// Falls back to the floor when the viewport is too short, in which case the
  /// page scrolls — an honest readable minimum beats clipped cells. Rows grow
  /// with [textScale] so large system fonts never overflow their cell.
  ///
  /// [rows] is the 4-6 count of calendar rows in this month.
  double monthRowHeight(int rows) {
    final chrome = isShort ? kMonthChromeShort : kMonthChrome;
    final per = math.max(0.0, screenHeight - chrome) / rows;
    final t = textScale.clamp(1.0, 1.8);
    return per.clamp(kMinMonthCell * t, kMaxMonthCell * t);
  }

  /// Day-marker diameter inside a mini calendar whose 7-wide cell is
  /// [cellWidth]. Today this is a hard 18pt, which overflows the ~14.6pt cell
  /// a 375pt phone produces.
  double miniMarker(double cellWidth) => math.min(18.0, cellWidth * 0.9);

  /// HabitDot diameter for a 7-dot strip [stripWidth] wide, allowing for the
  /// 6pt left padding the strip puts on every dot.
  double habitDotSize(double stripWidth) =>
      ((stripWidth - 6 * 6) / 7).clamp(22.0, 30.0);

  /// True when the habit strip must stack its label above the dots instead of
  /// sharing a row — on narrow content the label would wrap to 3 lines.
  bool get compactHabitStrip => contentWidth < 420;

  /// SectionHeader title size. Shrinks on short viewports where the header
  /// would otherwise eat most of the visible height.
  double titleSizeFor(double base) => isShort ? base * 0.75 : base;
}

/// Spacing token bases (unscaled). Always pass through [L.sp] / `L.gap*` so a
/// single scale applies — do not use these directly in layout code.
class G {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
}

/// Root wrapper — the single choke point for type scale.
///
/// Mount once above the app's `home`. Every `T.*` text style scales without
/// touching its ~69 call sites, because `Text` multiplies `TextStyle.fontSize`
/// by the ambient [MediaQuery.textScaler]. System accessibility scaling still
/// composes on top: `systemScaler * TextScaler.linear(layoutScale)`.
///
/// Text scale is never locked — only multiplied up or gently down on `xs`.
class TypeScale extends StatelessWidget {
  const TypeScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = L.of(context).typeScale;
    // Compose as one linear factor: the system's effective scale times ours.
    // `TextScaler` has no `*` operator, and its `textScaleFactor` getter is
    // deprecated, so read the magnitude through `scale(1.0)` and rebuild.
    final combined = mq.textScaler.scale(1.0) * scale;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(combined)),
      child: child,
    );
  }
}
