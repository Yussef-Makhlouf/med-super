import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';

/// Step 3 result — pharmacy order "submitted" screen (not a confirmed order:
/// the pharmacy still has to review the uploaded prescription image and
/// confirm before preparing it). Modeled closely on
/// `LabBookingConfirmationScreen`, the near-identical template for this flow.
class PharmacyOrderConfirmationScreen extends StatelessWidget {
  const PharmacyOrderConfirmationScreen({
    required this.confirmation,
    super.key,
  });

  final PharmacyOrderConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Blocks the Android hardware/gesture back button too, not just the
      // (already-absent) in-app back arrow — the order has already been
      // sent, so there's nothing left to go back and redo. "Track order" /
      // "Home" are the only ways off this screen.
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
                      'pharmacy_booking.confirmation.title'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'pharmacy_booking.confirmation.subtitle'.tr(),
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
                                  'pharmacy_booking.confirmation.order_number_label'
                                      .tr(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.mutedText2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '#${confirmation.orderNumber}',
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
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.mutedText2,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'pharmacy_booking.confirmation.eta_label'
                                      .tr(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.mutedText2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'pharmacy_booking.confirmation.eta_value'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900,
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
                        onPressed: () => context.go('/patient/orders'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.patientPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                        ),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: Text(
                          'pharmacy_booking.confirmation.track_cta'.tr(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/patient/home'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.borderMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                        ),
                        icon: const Icon(Icons.home_outlined),
                        label: Text(
                          'pharmacy_booking.confirmation.go_home_cta'.tr(),
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
