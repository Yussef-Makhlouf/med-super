import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';

/// Bottom action bar for the step-2 (select lab) screen — same visual
/// language as [LabBookingBottomBar] from step 1, but a different CTA
/// label/total format ("شامل الضريبة" instead of a test count).
class LabConfirmBottomBar extends StatelessWidget {
  const LabConfirmBottomBar({
    required this.totalPrice,
    required this.onContinue,
    required this.isSubmitting,
    super.key,
  });

  final int totalPrice;
  final VoidCallback? onContinue;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.patientPrimary.withValues(alpha: 0.08),
            blurRadius: 6,
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
              width: 140,
              child: FilledButton(
                onPressed: isSubmitting ? null : onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'lab_booking.select_lab.continue_cta'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'lab_booking.select_lab.grand_total_label'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText2,
                  ),
                ),
                Text(
                  '$totalPrice ج.م',
                  style: const TextStyle(
                    fontSize: 16,
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
