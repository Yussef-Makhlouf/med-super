import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Horizontal row of selectable day cards ("اختر اليوم"), each showing the
/// weekday name and day-of-month, matching the Figma schedule step.
class ScheduleDayChipBar extends StatelessWidget {
  const ScheduleDayChipBar({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DayCard(
                day: day,
                isSelected: _isSameDay(day, selectedDay),
                onTap: () => onSelected(day),
                locale: locale,
              ),
            ),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.locale,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.patientPrimary : AppColors.surfaceApp,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected
                ? AppColors.patientPrimary
                : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              DateFormat.E(locale).format(day),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.mutedText2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
