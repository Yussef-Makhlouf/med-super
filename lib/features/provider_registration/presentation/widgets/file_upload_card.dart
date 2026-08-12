import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

class FileUploadCard extends StatelessWidget {
  const FileUploadCard({
    required this.icon,
    required this.title,
    required this.maxSizeLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String maxSizeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.providerPrimary.withValues(alpha: 0.02),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.bodyText),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'provider_registration.verification.tap_to_upload_hint'.tr(),
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 4),
            Text(
              maxSizeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.borderMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
