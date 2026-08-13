import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

/// "ترتيب حسب" filter row on the lab-selection screen (step 2).
class LabSortChipBar extends StatelessWidget {
  const LabSortChipBar({
    required this.selected,
    required this.onSelected,
    required this.openNowOnly,
    required this.onToggleOpenNow,
    super.key,
  });

  final LabSortOption selected;
  final ValueChanged<LabSortOption> onSelected;

  /// Whether the "مفتوح الآن" filter chip is active — a filter, not a sort
  /// order, but rendered in the same chip row per the mockup.
  final bool openNowOnly;
  final VoidCallback onToggleOpenNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'lab_booking.select_lab.sort_by'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.tune, size: 18, color: AppColors.ink700),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(),
            _chip(LabSortOption.priceAsc, 'lab_booking.select_lab.sort_price'),
            _chip(
              LabSortOption.ratingDesc,
              'lab_booking.select_lab.sort_rating',
            ),
            _chip(LabSortOption.nearest, 'lab_booking.select_lab.sort_nearest'),
          ],
        ),
      ],
    );
  }

  Widget _filterChip() {
    return ChoiceChip(
      label: Text('lab_booking.select_lab.filter_open_now'.tr()),
      selected: openNowOnly,
      onSelected: (_) => onToggleOpenNow(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.patientPrimary.withValues(alpha: 0.1),
      side: BorderSide(
        color: openNowOnly ? AppColors.patientPrimary : AppColors.borderMedium,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: openNowOnly ? AppColors.patientPrimary : AppColors.mutedText2,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _chip(LabSortOption option, String labelKey) {
    final isActive = option == selected;
    return ChoiceChip(
      label: Text(labelKey.tr()),
      selected: isActive,
      onSelected: (_) => onSelected(option),
      backgroundColor: Colors.white,
      selectedColor: AppColors.patientPrimary.withValues(alpha: 0.1),
      side: BorderSide(
        color: isActive ? AppColors.patientPrimary : AppColors.borderMedium,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isActive ? AppColors.patientPrimary : AppColors.mutedText2,
      ),
      shape: const StadiumBorder(),
    );
  }
}
