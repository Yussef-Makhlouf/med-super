import 'package:flutter/material.dart';

/// Brand blue from Figma (~#2E6FF2).
const Color brandBlue = Color(0xFF2E6FF2);

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
