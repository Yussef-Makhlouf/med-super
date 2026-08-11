import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';

class SelectableTestCard extends StatelessWidget {
  const SelectableTestCard({
    required this.test,
    required this.isSelected,
    required this.onToggle,
    super.key,
  });

  final LabTest test;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: AppColors.surfaceApp,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
            color: isSelected ? AppColors.patientPrimary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.patientPrimary.withValues(alpha: 0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (test.isPackage)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.patientPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'lab_booking.package_badge'.tr(),
                      style: const TextStyle(
                        color: AppColors.patientPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  test.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (test.isPackage && test.includesCount != null)
                  _DetailChip(
                    icon: Icons.science_outlined,
                    label: 'lab_booking.includes_tests_count'.tr(
                      args: ['${test.includesCount}'],
                    ),
                  ),
                if (test.requiresFasting)
                  _DetailChip(
                    icon: Icons.no_food_outlined,
                    label: 'lab_booking.fasting_required'.tr(
                      args: ['${test.fastingHours ?? 8}'],
                    ),
                  )
                else
                  _DetailChip(
                    icon: Icons.no_food_outlined,
                    label: 'lab_booking.no_fasting'.tr(),
                  ),
                if (test.resultHours != null)
                  _DetailChip(
                    icon: Icons.timer_outlined,
                    label: 'lab_booking.results_in_hours'.tr(
                      args: ['${test.resultHours}'],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 17),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isSelected
                        ? AppColors.patientPrimary
                        : AppColors.patientPrimary.withValues(alpha: 0.1),
                    child: Icon(
                      isSelected ? Icons.remove : Icons.add,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.patientPrimary,
                    ),
                  ),
                  Text(
                    '${test.price} ${test.currency == 'EGP' ? 'ج.م' : test.currency}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.patientPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: AppColors.bodyText),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: AppColors.bodyText),
      ],
    );
  }
}
