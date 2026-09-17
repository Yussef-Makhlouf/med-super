import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';

enum _AppBadgeVariant { filled, soft, dot }

/// A single reusable pill/status-badge primitive (design system v2).
///
/// Generalizes two patterns that were previously built inline per-screen —
/// the "special offer" pill on the home promo banner and the small unread
/// dot on the notification bell icon — into one widget so future status
/// indicators (order/appointment state, etc.) reuse it instead of a new
/// one-off `Container` each time.
class AppBadge extends StatelessWidget {
  const AppBadge._({
    required this._variant,
    this.label,
    this.color = AppPalette.primary,
    this.onColor,
    this.bordered = false,
    super.key,
  });

  /// Solid pill — high-emphasis (e.g. "Special offer" on a colored surface).
  factory AppBadge.filled({
    required String label,
    Color color = AppPalette.primary,
    Color onColor = Colors.white,
    Key? key,
  }) => AppBadge._(
    variant: _AppBadgeVariant.filled,
    label: label,
    color: color,
    onColor: onColor,
    key: key,
  );

  /// Tinted pill — low-emphasis status tag (e.g. order/appointment state).
  ///
  /// [bordered] adds a subtle matching-color outline — used by call sites
  /// migrating from a pre-v2 pill style that had one (e.g. the appointment
  /// status pill), kept as an option rather than the default so plain
  /// tinted pills (order/lab status) stay unchanged.
  factory AppBadge.soft({
    required String label,
    Color color = AppPalette.primary,
    bool bordered = false,
    Key? key,
  }) => AppBadge._(
    variant: _AppBadgeVariant.soft,
    label: label,
    color: color,
    bordered: bordered,
    key: key,
  );

  /// Small solid dot — unread/attention indicator with no label.
  factory AppBadge.dot({Color color = AppPalette.error, Key? key}) =>
      AppBadge._(variant: _AppBadgeVariant.dot, color: color, key: key);

  final _AppBadgeVariant _variant;
  final String? label;
  final Color color;
  final Color? onColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    if (_variant == _AppBadgeVariant.dot) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final filled = _variant == _AppBadgeVariant.filled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: bordered
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label ?? '',
        style: textTheme.labelSmall?.copyWith(
          color: filled ? (onColor ?? Colors.white) : color,
        ),
      ),
    );
  }
}
