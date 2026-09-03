import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';

class UploadedFileTile extends StatelessWidget {
  const UploadedFileTile({
    required this.document,
    required this.onRemove,
    super.key,
  });

  final UploadedDocument document;
  final VoidCallback onRemove;

  bool get _isImage =>
      document.fileName.toLowerCase().endsWith('.jpg') ||
      document.fileName.toLowerCase().endsWith('.jpeg') ||
      document.fileName.toLowerCase().endsWith('.png');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  document.fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'provider_registration.verification.upload_success'.tr()} • ${document.sizeMb.toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.patientPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              _isImage ? Icons.image_outlined : Icons.description_outlined,
              color: AppColors.providerPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
