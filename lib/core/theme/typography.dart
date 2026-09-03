import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 TextTheme using IBM Plex Sans Arabic — matches the Figma
/// design system exactly (Regular/Medium/SemiBold/Bold), covers both Arabic
/// and Latin scripts, satisfying §6.8 bilingual parity.
TextTheme buildTextTheme({Brightness brightness = Brightness.light}) {
  final base = ThemeData(brightness: brightness).textTheme;
  return GoogleFonts.ibmPlexSansArabicTextTheme(base);
}
