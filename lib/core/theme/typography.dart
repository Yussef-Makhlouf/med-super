import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 TextTheme using Cairo — a typeface that covers both Arabic and
/// Latin scripts with equal quality, satisfying §6.8 bilingual parity.
TextTheme buildTextTheme({Brightness brightness = Brightness.light}) {
  final base = ThemeData(brightness: brightness).textTheme;
  return GoogleFonts.cairoTextTheme(base);
}
