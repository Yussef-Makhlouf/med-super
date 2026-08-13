import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_cost_estimate.dart';

/// Fixed, mocked home-collection service fee added on top of a partner's
/// `startingPrice` when the service type is home collection. No backend
/// estimate endpoint exists yet (see LAB_BOOKING_FLOW_TODO_AR.md open
/// decision #1), so this flat amount is a placeholder assumption until a
/// real per-request estimate is available.
const int kLabHomeServiceFeeEgp = 100;

/// "Cost estimate" card on the review step: an approximate tests total,
/// an optional home-collection fee row, a bold grand total, and a fixed
/// disclaimer that the final price is only settled after lab review.
class LabCostEstimateSection extends StatelessWidget {
  const LabCostEstimateSection({required this.estimate, super.key});

  final LabCostEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lab_booking.review.cost_estimate_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            labelKey: 'lab_booking.review.tests_estimate_label',
            value: estimate.testsEstimate,
          ),
          if (estimate.homeFee > 0) ...[
            const SizedBox(height: 8),
            _Row(
              labelKey: 'lab_booking.review.home_fee_label',
              value: estimate.homeFee,
            ),
          ],
          const Divider(height: 24, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'lab_booking.review.total_estimate_label'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              Text(
                '${estimate.total} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.patientPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoTealBg,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.infoTealText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'lab_booking.review.estimate_disclaimer'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.infoTealText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.labelKey, required this.value});

  final String labelKey;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          labelKey.tr(),
          style: const TextStyle(fontSize: 13, color: AppColors.mutedText2),
        ),
        Text(
          '$value ج.م',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}
