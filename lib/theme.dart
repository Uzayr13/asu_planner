import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens approximated from the reference screenshots.
class C {
  static const navy = Color(0xFF12223F);
  static const gold = Color(0xFF8B6F2E);
  static const goldBright = Color(0xFFC9A24A);
  static const paper = Color(0xFFE8E4D6);
  static const tab = Color(0xFFD8D3C0);
  static const input = Color(0x99C9D0E0); // ~60% blue-grey
  static const line = Color(0xFFB9B2A0);
  static const tealTop = Color(0xFF1B5160);
  static const tealBottom = Color(0xFF0F3640);
  static const coverNavy = Color(0xFF0D1B2E);
  static const silver = Color(0xFFC9C9C9);
  static const holiday = Color(0xFFA23B3B); // public holidays
}

class T {
  /// English display serif (Playfair-style).
  static TextStyle serif(double size, {Color color = C.navy, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: size, color: color, fontWeight: w);

  /// UI sans (Lato-style).
  static TextStyle sans(double size,
          {Color color = C.navy, FontWeight w = FontWeight.w400, double spacing = 0}) =>
      GoogleFonts.lato(fontSize: size, color: color, fontWeight: w, letterSpacing: spacing);

  /// Arabic calligraphic display.
  static TextStyle arDisplay(double size, {Color color = C.gold}) =>
      GoogleFonts.amiri(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.2);

  /// Arabic UI text.
  static TextStyle ar(double size, {Color color = C.navy, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.notoNaskhArabic(fontSize: size, color: color, fontWeight: w);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.paper,
      colorScheme: ColorScheme.fromSeed(seedColor: C.navy, surface: C.paper),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: C.navy),
    );
