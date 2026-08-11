import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

class ReviewRow {
  const ReviewRow(this.label, this.value);
  final String label;
  final String value;
}

class ReviewSectionCard extends StatelessWidget {
  const ReviewSectionCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.onEdit,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<ReviewRow> rows;
  final VoidCallback onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.surfaceReviewCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceReviewCardBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.providerPrimary,
                  ),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(color: AppColors.providerPrimary),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.providerPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: AppColors.providerPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.ink700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
