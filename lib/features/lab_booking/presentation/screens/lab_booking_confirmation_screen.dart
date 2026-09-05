import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';

/// Step 3 result — lab request "submitted" screen (not a confirmed booking:
/// lab staff still has to review the request and respond with a quote).
///
/// Rebuilt 2026-09-05: the old copy claimed an immediate "booking number"
/// and an "expected response" ETA, neither of which the real backend
/// produces at creation time (`POST /v1/lab-orders` only ever returns
/// `{labOrderId, status: 'REQUESTED'}` — no ETA field exists, and a booking
/// code isn't issued until `ConfirmLabBookingUseCase` runs, after a quote).
/// Shows the real order id (reusing `shortOrderId`, the same truncation
/// `pharmacy_booking`'s confirmation/detail screens share) and links to "My
/// Lab Requests" to track real status from here on.
class LabBookingConfirmationScreen extends StatelessWidget {
  const LabBookingConfirmationScreen({required this.confirmation, super.key});

  final LabBookingConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Blocks the Android hardware/gesture back button too — the request
      // has already been sent, so there's nothing left to go back and redo.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceApp,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'lab_booking.confirmation.order_number_label'
                                      .tr(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.mutedText2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '#${shortOrderId(confirmation.orderId)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.patientPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.patientPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
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
                                      confirmation.branchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                    Text(
                                      confirmation.branchAddress,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          '/patient/orders/lab/${confirmation.orderId}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.patientPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                        ),
                        icon: const Icon(Icons.assignment_outlined),
                        label: Text('lab_booking.confirmation.track_cta'.tr()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/patient/home'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(
                            color: AppColors.borderMedium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                        ),
                        child: Text(
                          'lab_booking.confirmation.go_home_cta'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
