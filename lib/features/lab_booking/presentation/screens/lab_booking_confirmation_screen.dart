import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

/// Step 3 result — lab request "submitted" screen (not a confirmed booking:
/// the lab still has to review the uploaded request image and respond).
/// Figma node 14:1396 ("تأكيد الحجز - Booking Confirmation"), corrected per
/// the lab-booking mockup-fix TODO: the mockup's copy was a copy/paste leak
/// from the pharmacy flow (it said "the pharmacy" instead of "the lab", used
/// delivery-time wording, and used a delivery-truck icon on the primary
/// button) — all three are fixed here rather than reproduced literally. The
/// design includes a confetti animation; reproduced here as a static
/// checkmark badge (matching [SimpleSuccessScreen]'s visual language) rather
/// than pulling in a new animation dependency for a single one-off effect.
class LabBookingConfirmationScreen extends StatelessWidget {
  const LabBookingConfirmationScreen({required this.confirmation, super.key});

  final LabBookingConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Blocks the Android hardware/gesture back button too, not just the
      // (already-removed) in-app back arrow — the request is already sent,
      // so there's nothing left to go back and redo. "Track request" / "Home"
      // are the only ways off this screen.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // No back button here on purpose: the request has already been
              // sent, so there's nothing left to go back and re-do — only
              // "track" or "go home" are meaningful next steps.
              const SizedBox(height: 12),
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
                    Text(
                      'lab_booking.confirmation.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.bodyText),
                    ),
                    const SizedBox(height: 16),
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
                    _InfoTile(
                      label: 'lab_booking.confirmation.expected_response_label'
                          .tr(),
                      value: 'lab_booking.confirmation.expected_response_value'
                          .tr(args: ['${confirmation.expectedResponseHours}']),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.go('/patient/orders'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.patientPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                        ),
                      ),
                      // Tracking/document icon — the mockup used a
                      // delivery-truck icon here, a copy/paste leak from the
                      // pharmacy flow's "order on the way" concept that doesn't
                      // apply to a lab request still awaiting review.
                      icon: const Icon(Icons.assignment_outlined),
                      label: Text('lab_booking.confirmation.track_cta'.tr()),
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
      width: double.infinity,
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
