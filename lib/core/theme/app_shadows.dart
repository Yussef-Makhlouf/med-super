import 'package:flutter/material.dart';

/// Soft, low-contrast elevation (design system v3, 2026-09).
///
/// Depth comes mostly from surface color steps, not shadow — these stay
/// diffuse and low-alpha rather than the harsh default drop shadows. Tinted
/// with a cool neutral (`#10151C`), matching the reverted blue-grey ink in
/// `AppPalette` rather than v2's warm-ink experiment.
abstract final class AppShadows {
  static const List<BoxShadow> resting = [
    BoxShadow(
      color: Color(0x0A10151C),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x1410151C),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];
}
