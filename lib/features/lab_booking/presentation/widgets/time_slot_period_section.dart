import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_time_slot.dart';

/// One labelled period (morning/evening) of selectable time-slot chips.
class TimeSlotPeriodSection extends StatelessWidget {
  const TimeSlotPeriodSection({
    required this.periodLabel,
    required this.slots,
    required this.selectedTime,
    required this.onSelected,
    super.key,
  });

  final String periodLabel;
  final List<LabTimeSlot> slots;
  final String? selectedTime;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            periodLabel,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText2),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final slot in slots)
              _TimeSlotChip(
                slot: slot,
                isSelected: slot.time == selectedTime,
                label: AppFormatters.time12h(slot.time, locale: locale),
                onTap: slot.isAvailable ? () => onSelected(slot.time) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final LabTimeSlot slot;
  final bool isSelected;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !slot.isAvailable;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.patientPrimary
              : isDisabled
              ? AppColors.surfaceApp
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected
                ? AppColors.patientPrimary
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDisabled
                ? AppColors.borderMedium
                : AppColors.bodyText,
          ),
        ),
      ),
    );
  }
}
