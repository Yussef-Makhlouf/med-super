import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// A tinted, rounded-square icon container (design system v2) — an icon on a
/// 12%-alpha wash of its own color.
///
/// Previously re-implemented ad hoc in at least three places (the home
/// screen's quick-action cards, the doctor result card's meta rows, the
/// notification card's leading icon) with slightly different sizes/radii
/// each time. One widget now, sized per call site via [size]/[iconSize].
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
