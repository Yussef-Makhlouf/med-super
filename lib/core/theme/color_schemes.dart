import 'package:flutter/material.dart';

/// Brand blue — design system v1 (2026-09), refined from the original
/// Figma blue (#2E6FF2) into a slightly deeper, more saturated tone for
/// better contrast on white and a more premium feel on filled buttons.
const Color brandBlue = Color(0xFF2452D9);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: brandBlue,
  brightness: Brightness.light,
  primary: brandBlue,
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: brandBlue,
  brightness: Brightness.dark,
  primary: brandBlue,
  surface: const Color(0xFF000000),
  onSurface: const Color(0xFFFFFFFF),
);
