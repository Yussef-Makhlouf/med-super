import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';

class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    required this.categories,
    required this.activeId,
    required this.onSelected,
    super.key,
  });

  final List<LabTestCategory> categories;
  final String? activeId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category.id == activeId;
          return ChoiceChip(
            label: Text(category.labelKey.tr()),
            selected: isActive,
            onSelected: (_) => onSelected(isActive ? null : category.id),
            backgroundColor: AppColors.surfaceApp,
            selectedColor: AppColors.tealBg,
            side: BorderSide(
              color: isActive
                  ? AppColors.tealAccent.withValues(alpha: 0.2)
                  : AppColors.borderLight,
            ),
            labelStyle: TextStyle(
              color: isActive ? AppColors.tealAccent : AppColors.bodyText,
              fontWeight: FontWeight.w500,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
