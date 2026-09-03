import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/schedule_day_chip_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/time_slot_period_section.dart';

/// Opens the day/time/address edit modal for the home-collection service
/// method, seeded from the current [selectedScheduleDayProvider] /
/// [selectedTimeSlotProvider] / [selectedLabAddressProvider] values.
/// Returns `true` once the user saves, `null`/`false` if dismissed.
Future<bool?> showLabScheduleEditModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (context) => const LabScheduleEditModal(),
  );
}

/// Re-uses the day/time pickers built for the (now removed) standalone
/// schedule step — relocated here so the review screen can offer the same
/// controls inside a modal instead of a full page. Also lets the patient
/// edit the home-collection address.
class LabScheduleEditModal extends ConsumerStatefulWidget {
  const LabScheduleEditModal({super.key});

  @override
  ConsumerState<LabScheduleEditModal> createState() =>
      _LabScheduleEditModalState();
}

class _LabScheduleEditModalState extends ConsumerState<LabScheduleEditModal> {
  late DateTime _day;
  late String? _time;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _day = ref.read(selectedScheduleDayProvider);
    _time = ref.read(selectedTimeSlotProvider);
    _addressController = TextEditingController(
      text: ref.read(selectedLabAddressProvider),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _time != null && _addressController.text.trim().isNotEmpty;

  void _save() {
    ref.read(selectedScheduleDayProvider.notifier).select(_day);
    ref.read(selectedTimeSlotProvider.notifier).select(_time);
    ref
        .read(selectedLabAddressProvider.notifier)
        .select(_addressController.text.trim());
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(labAvailableDaysProvider);
    final slotsByPeriod = ref.watch(labTimeSlotsByPeriodProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Text(
                'lab_booking.schedule_payment.choose_day_title'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              ScheduleDayChipBar(
                days: days,
                selectedDay: _day,
                onSelected: (day) => setState(() => _day = day),
              ),
              const SizedBox(height: 24),
              Text(
                'lab_booking.schedule_payment.choose_time_title'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              TimeSlotPeriodSection(
                periodLabel: 'lab_booking.schedule_payment.morning_period_label'
                    .tr(),
                slots: slotsByPeriod['morning'] ?? const [],
                selectedTime: _time,
                onSelected: (time) => setState(() => _time = time),
              ),
              const SizedBox(height: 16),
              TimeSlotPeriodSection(
                periodLabel: 'lab_booking.schedule_payment.evening_period_label'
                    .tr(),
                slots: slotsByPeriod['evening'] ?? const [],
                selectedTime: _time,
                onSelected: (time) => setState(() => _time = time),
              ),
              const SizedBox(height: 24),
              Text(
                'lab_booking.review.address_label'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                onChanged: (_) => setState(() {}),
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceApp,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.patientPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                    ),
                  ),
                  child: const Text(
                    // Placeholder — no `save_cta` key exists in the
                    // translation contract for this modal yet. Flagged in
                    // the C3 agent report for review.
                    'حفظ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
