import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 [TextTheme] on IBM Plex Sans Arabic — the family stays fixed
/// (design system v2, 2026-09) because it's one of the few characterful
/// choices that actually covers Arabic glyphs correctly: the app is fully
/// bilingual with RTL, and nearly every visible string is routed through
/// `.tr()`, so a Latin-only display face would silently fall back and read
/// broken in `ar`. Personality instead comes from a deliberate modular scale
/// (~1.25x ratio) and weight/tracking contrast rather than a second family.
TextTheme buildTextTheme({Brightness brightness = Brightness.light}) {
  final base = ThemeData(brightness: brightness).textTheme;
  final withFamily = GoogleFonts.ibmPlexSansArabicTextTheme(base);

  // `.merge` (not a raw override) so every role keeps the Arabic-covering
  // `fontFamily`/`fontFamilyFallback` from `withFamily` — only the scale's
  // size/weight/tracking/height are replaced.
  TextStyle scale(
    TextStyle? role,
    double fontSize,
    FontWeight fontWeight, {
    double? letterSpacing,
    double? height,
  }) =>
      (role ?? const TextStyle()).merge(
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: height,
        ),
      );

  return withFamily.copyWith(
    displayLarge: scale(
      withFamily.displayLarge,
      40,
      FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.15,
    ),
    displayMedium: scale(
      withFamily.displayMedium,
      34,
      FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.18,
    ),
    displaySmall: scale(
      withFamily.displaySmall,
      28,
      FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.2,
    ),
    headlineLarge: scale(
      withFamily.headlineLarge,
      24,
      FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.25,
    ),
    headlineMedium: scale(
      withFamily.headlineMedium,
      22,
      FontWeight.w700,
      letterSpacing: -0.1,
      height: 1.25,
    ),
    headlineSmall: scale(
      withFamily.headlineSmall,
      20,
      FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: scale(withFamily.titleLarge, 20, FontWeight.w700, height: 1.3),
    titleMedium: scale(
      withFamily.titleMedium,
      16,
      FontWeight.w700,
      height: 1.35,
    ),
    titleSmall: scale(
      withFamily.titleSmall,
      14,
      FontWeight.w600,
      height: 1.35,
    ),
    bodyLarge: scale(withFamily.bodyLarge, 16, FontWeight.w400, height: 1.5),
    bodyMedium: scale(withFamily.bodyMedium, 14, FontWeight.w400, height: 1.5),
    bodySmall: scale(
      withFamily.bodySmall,
      12,
      FontWeight.w400,
      height: 1.45,
    ),
    labelLarge: scale(withFamily.labelLarge, 14, FontWeight.w600, height: 1.3),
    labelMedium: scale(
      withFamily.labelMedium,
      12,
      FontWeight.w700,
      height: 1.3,
    ),
    labelSmall: scale(
      withFamily.labelSmall,
      11,
      FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.3,
    ),
  );
}
