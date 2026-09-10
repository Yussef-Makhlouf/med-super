import 'package:flutter/material.dart';

/// Soft, low-contrast elevation (design system v1, 2026-09).
///
/// Depth comes mostly from surface color steps, not shadow — these stay
/// diffuse and low-alpha rather than the harsh default drop shadows.
abstract final class AppShadows {
  static const List<BoxShadow> resting = [
    BoxShadow(
      color: Color(0x0A10151C),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x1410151C),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
