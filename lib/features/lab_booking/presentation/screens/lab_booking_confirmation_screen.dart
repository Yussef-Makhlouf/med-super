import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';
import 'package:solar_icons/solar_icons.dart';

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
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tealAccent.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        SolarIconsBold.checkCircle,
                        color: AppColors.tealAccent,
                        size: 72,
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
                    const SizedBox(height: 14),
                    AppBadge.soft(
                      label: 'lab_booking.orders.status_requested'.tr(),
                      color: AppPalette.warning,
                      bordered: true,
                    ),
                    const SizedBox(height: 24),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(17),
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
                              const AppIconTile(
                                icon: SolarIconsOutline.testTube,
                                color: AppColors.patientPrimary,
                                size: 48,
                                iconSize: 24,
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
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          '/patient/orders/lab/${confirmation.orderId}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.patientPrimary,
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(SolarIconsOutline.clipboard),
                        label: Text('lab_booking.confirmation.track_cta'.tr()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.go('/patient/home'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.borderMedium,
                          ),
                          shape: const StadiumBorder(),
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
