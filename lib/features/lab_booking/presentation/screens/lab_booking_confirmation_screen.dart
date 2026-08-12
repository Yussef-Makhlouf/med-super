import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

/// Step 3 result — booking success screen. Figma node 14:1396
/// ("تأكيد الحجز - Booking Confirmation"). The design includes a confetti
/// animation; reproduced here as a static checkmark badge (matching
/// [SimpleSuccessScreen]'s visual language) rather than pulling in a new
/// animation dependency for a single one-off effect.
class LabBookingConfirmationScreen extends StatelessWidget {
  const LabBookingConfirmationScreen({required this.confirmation, super.key});

  final LabBookingConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tealAccent.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.tealAccent,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'lab_booking.confirmation.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: 'lab_booking.confirmation.booking_number_prefix'
                          .tr(),
                      style: const TextStyle(color: AppColors.bodyText),
                      children: [
                        TextSpan(
                          text: ' #${confirmation.bookingNumber}',
                          style: const TextStyle(
                            color: AppColors.patientPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceApp,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.patientPrimary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(
                            Icons.biotech_outlined,
                            color: AppColors.patientPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                confirmation.labName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink900,
                                ),
                              ),
                              Text(
                                confirmation.labAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: 'lab_booking.confirmation.date_label'.tr(),
                          value: AppFormatters.shortDate(
                            confirmation.date,
                            locale: locale,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _InfoTile(
                          label: 'lab_booking.confirmation.time_label'.tr(),
                          value: confirmation.time,
                        ),
                      ),
                    ],
                  ),
                  if (confirmation.fastingHours != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmberBg,
                        border: Border.all(color: AppColors.warningAmberBorder),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.warningAmberText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'lab_booking.confirmation.instructions_title'
                                      .tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningAmberText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'lab_booking.confirmation.instructions_body'
                                      .tr(
                                        args: ['${confirmation.fastingHours}'],
                                      ),
                                  style: const TextStyle(
                                    color: AppColors.warningAmberText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go('/patient/appointments'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                    ),
                    child: Text(
                      'lab_booking.confirmation.go_to_bookings_cta'.tr(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/patient/home'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.borderMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                    ),
                    child: Text('lab_booking.confirmation.go_home_cta'.tr()),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceApp,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}
