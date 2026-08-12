import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_confirm_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/payment_method_option.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/schedule_day_chip_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/time_slot_period_section.dart';

/// Step 3 of the lab booking flow — pick a day/time and payment method,
/// then confirm the booking. Figma node 14:1240
/// ("حجز الفحوصات المخبرية - الموعد والدفع").
class LabSchedulePaymentScreen extends ConsumerStatefulWidget {
  const LabSchedulePaymentScreen({super.key});

  @override
  ConsumerState<LabSchedulePaymentScreen> createState() =>
      _LabSchedulePaymentScreenState();
}

class _LabSchedulePaymentScreenState
    extends ConsumerState<LabSchedulePaymentScreen> {
  bool _confirming = false;

  Future<void> _confirm() async {
    final selectedTime = ref.read(selectedTimeSlotProvider);
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'lab_booking.schedule_payment.select_time_first'.tr(),
          ),
        ),
      );
      return;
    }

    final partners = ref.read(labPartnersProvider).value ?? const [];
    final explicitLabId = ref.read(selectedLabPartnerProvider);
    final labId = explicitLabId ?? (partners.isEmpty ? null : partners.first.id);
    if (labId == null) return;

    setState(() => _confirming = true);
    final testIds = ref.read(selectedLabTestsProvider).toList();
    final selectedDay = ref.read(selectedScheduleDayProvider);
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final result = await ref
        .read(confirmLabBookingUseCaseProvider)
        .call(
          labId: labId,
          testIds: testIds,
          scheduledDate: selectedDay,
          scheduledTime: selectedTime,
          paymentMethod: paymentMethod.apiValue,
        );
    if (!mounted) return;
    setState(() => _confirming = false);
    result.when(
      ok: (confirmation) =>
          context.push('/patient/lab/confirmation', extra: confirmation),
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lab_booking.schedule_payment.confirm_error'.tr()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(labAvailableDaysProvider);
    final slotsByPeriod = ref.watch(labTimeSlotsByPeriodProvider);
    final selectedDay = ref.watch(selectedScheduleDayProvider);
    final selectedTime = ref.watch(selectedTimeSlotProvider);
    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final totalAsync = ref.watch(selectedLabTestsTotalProvider);
    final selectedIds = ref.watch(selectedLabTestsProvider);
    final allTestsAsync = ref.watch(allLabTestsProvider);
    final partnersAsync = ref.watch(labPartnersProvider);
    final explicitLabId = ref.watch(selectedLabPartnerProvider);

    final partners = partnersAsync.value ?? const [];
    final selectedLabId =
        explicitLabId ?? (partners.isEmpty ? null : partners.first.id);
    final matchingPartners = partners.where((p) => p.id == selectedLabId);
    final labName = matchingPartners.isEmpty
        ? null
        : matchingPartners.first.name;
    final testNames = (allTestsAsync.value?.tests ?? const [])
        .where((t) => selectedIds.contains(t.id))
        .map((t) => t.name)
        .join('، ');

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            StepProgressHeader(
              // Same step labels/order as the other two steps of this flow
              // — the stepper must read identically across all three
              // screens, not per-screen wording.
              stepLabels: [
                'lab_booking.step_select_tests'.tr(),
                'lab_booking.step_select_lab'.tr(),
                'lab_booking.step_schedule_payment'.tr(),
              ],
              currentStep: 2,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _BookingSummaryCard(
                    labName: labName,
                    testNames: testNames,
                    totalPrice: totalAsync.value ?? 0,
                  ),
                  const SizedBox(height: 24),
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
                    selectedDay: selectedDay,
                    onSelected: (day) => ref
                        .read(selectedScheduleDayProvider.notifier)
                        .select(day),
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
                    periodLabel:
                        'lab_booking.schedule_payment.morning_period_label'
                            .tr(),
                    slots: slotsByPeriod['morning'] ?? const [],
                    selectedTime: selectedTime,
                    onSelected: (time) =>
                        ref.read(selectedTimeSlotProvider.notifier).select(
                          time,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TimeSlotPeriodSection(
                    periodLabel:
                        'lab_booking.schedule_payment.evening_period_label'
                            .tr(),
                    slots: slotsByPeriod['evening'] ?? const [],
                    selectedTime: selectedTime,
                    onSelected: (time) =>
                        ref.read(selectedTimeSlotProvider.notifier).select(
                          time,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'lab_booking.schedule_payment.payment_method_title'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<LabPaymentMethod>(
                    groupValue: selectedPayment,
                    onChanged: (method) {
                      if (method != null) {
                        ref
                            .read(selectedPaymentMethodProvider.notifier)
                            .select(method);
                      }
                    },
                    child: Column(
                      children: [
                        for (final method in LabPaymentMethod.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PaymentMethodOption(
                              method: method,
                              isSelected: method == selectedPayment,
                              onSelected: () => ref
                                  .read(selectedPaymentMethodProvider.notifier)
                                  .select(method),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            LabScheduleConfirmBar(
              totalPrice: totalAsync.value ?? 0,
              isSubmitting: _confirming,
              // Disabled until a time slot is chosen — day and payment
              // method always have a default, so the time slot is the
              // only field that can genuinely be left unset.
              onConfirm: selectedTime == null ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.labName,
    required this.testNames,
    required this.totalPrice,
  });

  final String? labName;
  final String testNames;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.patientPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'lab_booking.schedule_payment.booking_summary_title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (labName != null)
            Text(
              labName!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          if (testNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              testNames,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText2,
              ),
            ),
          ],
          const Divider(height: 24, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'lab_booking.schedule_payment.summary_total_label'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText2,
                ),
              ),
              Text(
                '$totalPrice ج.م',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.patientPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Balances the trailing back button's width so the title stays
          // visually centered now that nothing occupies the leading slot.
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'lab_booking.schedule_payment.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.patientPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
