import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:solar_icons/solar_icons.dart';

class _AuthSecondaryEntryCard extends StatelessWidget {
  const _AuthSecondaryEntryCard({
    required this.questionKey,
    required this.actionKey,
    required this.icon,
    required this.onTap,
  });

  final String questionKey;
  final String actionKey;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: actionKey.tr(),
      child: Material(
        color: AppPalette.paper,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppPalette.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCE8FF),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: brandBlue, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionKey.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        actionKey.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          color: brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: brandBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderEntryCard extends StatelessWidget {
  const ProviderEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _AuthSecondaryEntryCard(
    questionKey: 'auth.healthcare_provider_question',
    actionKey: 'auth.provider_login_cta',
    icon: SolarIconsOutline.stethoscope,
    onTap: onTap,
  );
}

class PatientEntryCard extends StatelessWidget {
  const PatientEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _AuthSecondaryEntryCard(
    questionKey: 'auth.not_healthcare_provider_question',
    actionKey: 'auth.back_to_patient_login_cta',
    icon: SolarIconsOutline.user,
    onTap: onTap,
  );
}
