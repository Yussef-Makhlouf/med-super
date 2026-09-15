import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Brand accent. Reads from [AppPalette.primary] — v3 (2026-09) reverted
/// that token's *value* back to the original blue (`#2452D9`) at the user's
/// request, after a brief warm-rust/terracotta v2 pass. Kept as the same
/// top-level identifier — `brandBlue` — rather than renamed, because ~60
/// files across every feature (including `lab_booking`) reference it by name
/// as *the* primary accent; repointing its value (in `app_palette.dart`,
/// not here) cascades any future rebrand consistently everywhere without
/// editing those files individually.
const Color brandBlue = AppPalette.primary;

/// Explicit role assignment rather than `ColorScheme.fromSeed` — every role
/// here is a deliberate pick from [AppPalette] rather than algorithmically
/// derived from one seed, so palette changes (like the v2→v3 color revert)
/// only ever touch `app_palette.dart`, never the role wiring below.
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.primary,
  brightness: Brightness.light,
  primary: AppPalette.primary,
  onPrimary: Colors.white,
  primaryContainer: AppPalette.primarySoft,
  onPrimaryContainer: AppPalette.primary,
  secondary: AppPalette.secondary,
  onSecondary: Colors.white,
  secondaryContainer: AppPalette.secondarySoft,
  onSecondaryContainer: AppPalette.secondary,
  error: AppPalette.error,
  onError: Colors.white,
  errorContainer: AppPalette.errorSoft,
  onErrorContainer: AppPalette.error,
  surface: AppPalette.paper,
  onSurface: AppPalette.ink,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: AppPalette.paper,
  surfaceContainer: AppPalette.surfaceSunken,
  surfaceContainerHigh: AppPalette.surfaceSunken,
  onSurfaceVariant: AppPalette.inkMuted,
  outline: AppPalette.border,
  outlineVariant: AppPalette.border,
);

// Dark stays algorithmic/untouched — `app.dart` hardcodes
// `themeMode: ThemeMode.light`, so this is unreachable in the shipped app;
// not worth hand-tuning for a theme that never renders.
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.primary,
  brightness: Brightness.dark,
  primary: AppPalette.primary,
  surface: const Color(0xFF000000),
  onSurface: const Color(0xFFFFFFFF),
);
