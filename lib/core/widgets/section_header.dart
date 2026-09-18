import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_spacing.dart';

/// Section title with an optional trailing action, used to introduce a
/// list/grid on a scrollable screen (specialties, featured doctors, etc.).
///
/// Promoted from `patient_home_screen.dart`'s private `_SectionHeader` into a
/// shared primitive so every patient surface gets the same accent-bar
/// treatment instead of re-inventing it per screen.
///
/// The accent bar is built as a nested `Row` — not a `Positioned`/hardcoded
/// side — so it lands at the title's logical *start* (right before it in
/// reading order) in both `en` and `ar` automatically. This mirrors a past
/// fix: a physical `Alignment`/`Positioned` here would put the bar on the
/// wrong visual side once the locale flips.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must both be set or both be omitted',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(color: AppPalette.ink),
            ),
          ],
        ),
      ],
    );
  }
}
