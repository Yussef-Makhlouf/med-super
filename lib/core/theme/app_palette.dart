import 'package:flutter/material.dart';

/// Design system v3 (2026-09) — same token structure as the "Warm Clinical"
/// v2 palette (one dominant accent, one secondary, warm/cool-neutral base,
/// semantic success/warning/error), but with the color *values* reverted to
/// the original blue identity (`brandBlue` #2452D9) at the user's request.
/// Every screen still reads through these tokens — only the hues changed —
/// so this is the single place a future palette swap needs to touch.
/// Deliberately separate from [AppColors] (`app_colors.dart`), which stays
/// reserved for `lab_booking` + `provider_registration`'s own Figma-matched
/// palette — don't merge the two.
abstract final class AppPalette {
  // Neutrals — cool blue-grey.
  static const ink = Color(0xFF1A2B4A);
  static const inkMuted = Color(0xFF8A94A6);
  static const inkFaint = Color(0xFF9CA3AF);
  static const paper = Color(0xFFF3F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFE8EDF5);
  static const border = Color(0xFFE5EAF2);

  // Accents — one dominant, one secondary.
  static const primary = Color(0xFF2452D9);
  static const primarySoft = Color(0xFFDCE8FF);
  static const secondary = Color(0xFF0F766E);
  static const secondarySoft = Color(0xFFD7ECE9);

  // Semantic.
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFDF2E9);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0xFFFEE2E2);
}
