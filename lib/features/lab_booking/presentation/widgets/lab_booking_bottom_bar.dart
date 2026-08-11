import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';

class LabBookingBottomBar extends StatelessWidget {
  const LabBookingBottomBar({
    required this.selectedCount,
    required this.totalPrice,
    required this.onContinue,
    super.key,
  });

  final int selectedCount;
  final int totalPrice;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceApp,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.patientPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 230,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'lab_booking.select_lab_cta'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'lab_booking.total_label'.tr(args: ['$selectedCount']),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.bodyText,
                  ),
                ),
                Text(
                  '$totalPrice ج.م',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.patientPrimary,
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
