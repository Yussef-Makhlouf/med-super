import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';

/// Bottom action bar for the step-2 (select lab) screen — a single
/// full-width CTA. The mockup for this step carries no price/total in the
/// bottom bar (pricing is only known once the request is reviewed), so
/// unlike step 1's bottom bar this one is CTA-only.
class LabConfirmBottomBar extends StatelessWidget {
  const LabConfirmBottomBar({
    required this.onContinue,
    required this.isSubmitting,
    super.key,
  });

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
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitting ? null : onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.patientPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}
