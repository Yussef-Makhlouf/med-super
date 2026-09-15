import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/auth/presentation/utils/auth_validators.dart';
import 'package:solar_icons/solar_icons.dart';

/// Live strength label + requirement chips shown under a new-password field,
/// shared by [SetPasswordScreen] and [ResetPasswordScreen] — both wire it to
/// their own password controller and rebuild on every keystroke.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strength = passwordStrength(password);
    final (strengthLabel, strengthColor) = switch (strength) {
      PasswordStrength.weak => (
        'auth.password_strength_weak'.tr(),
        AppPalette.error,
      ),
      PasswordStrength.medium => (
        'auth.password_strength_medium'.tr(),
        AppPalette.warning,
      ),
      PasswordStrength.strong => (
        'auth.password_strength_strong'.tr(),
        AppPalette.success,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          Row(
            children: [
              Text(
                strengthLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RequirementChip(
              label: 'auth.requirement_length'.tr(),
              met: passwordHasMinLength(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_uppercase'.tr(),
              met: passwordHasUppercase(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_lowercase'.tr(),
              met: passwordHasLowercase(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_number'.tr(),
              met: passwordHasNumber(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_symbol'.tr(),
              met: passwordHasSymbol(password),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppPalette.success : AppPalette.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: met ? AppPalette.successSoft : AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: met
              ? AppPalette.success.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? SolarIconsBold.checkCircle : SolarIconsOutline.checkCircle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
