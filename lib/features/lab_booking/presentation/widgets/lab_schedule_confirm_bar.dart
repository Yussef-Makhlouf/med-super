import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Full-width "Confirm payment (total)" bottom action bar for the
/// schedule & payment step.
class LabScheduleConfirmBar extends StatelessWidget {
  const LabScheduleConfirmBar({
    required this.totalPrice,
    required this.isSubmitting,
    required this.onConfirm,
    super.key,
  });

  final int totalPrice;
  final bool isSubmitting;
  final VoidCallback? onConfirm;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.xl),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'lab_booking.schedule_payment.confirm_payment_cta'
                                .tr(args: ['$totalPrice']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const _TermsNotice(),
          ],
        ),
      ),
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text.rich(
        TextSpan(
          text: 'lab_booking.schedule_payment.confirm_terms_prefix'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
          children: [
            const TextSpan(text: ' '),
            TextSpan(
              text: 'lab_booking.schedule_payment.confirm_terms_link'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.patientPrimary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              // No terms page exists yet in this app — same no-op-link
              // convention used elsewhere (e.g. the header's help icon).
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
