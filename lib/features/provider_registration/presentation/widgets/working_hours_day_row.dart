import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';

const _dayLabels = {
  Weekday.saturday: 'السبت',
  Weekday.sunday: 'الأحد',
  Weekday.monday: 'الاثنين',
  Weekday.tuesday: 'الثلاثاء',
  Weekday.wednesday: 'الأربعاء',
  Weekday.thursday: 'الخميس',
  Weekday.friday: 'الجمعة',
};

class WorkingHoursDayRow extends StatelessWidget {
  const WorkingHoursDayRow({
    required this.day,
    required this.onToggle,
    required this.onPickFrom,
    required this.onPickTo,
    super.key,
  });

  final ClinicWorkingDay day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  String _fmt(ClinicTime? t) {
    if (t == null) return '--:--';
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: day.isEnabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.borderMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _dayLabels[day.day]!,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink900),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: day.isEnabled,
                  onChanged: (v) => onToggle(v ?? false),
                  activeColor: AppColors.providerPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: _fmt(day.from),
                    enabled: day.isEnabled,
                    onTap: onPickFrom,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'إلى',
                    style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                  ),
                ),
                Expanded(
                  child: _TimeField(
                    label: _fmt(day.to),
                    enabled: day.isEnabled,
                    onTap: onPickTo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceApp,
          border: Border.all(color: AppColors.borderMedium),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
