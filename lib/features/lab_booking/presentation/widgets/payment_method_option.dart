import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';

/// Single radio-style row for one [LabPaymentMethod] option, with a small
/// grey subtitle line under the label (e.g. "Visa, Mastercard, Meeza").
class PaymentMethodOption extends StatelessWidget {
  const PaymentMethodOption({
    required this.method,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final LabPaymentMethod method;
  final bool isSelected;
  final VoidCallback onSelected;

  IconData get _icon => switch (method) {
    LabPaymentMethod.onlinePayment => Icons.credit_card,
    LabPaymentMethod.payAtService => Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected
                ? AppColors.patientPrimary
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, color: AppColors.bodyText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    method.labelKey.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitleKey.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
              ),
            ),
            Radio<LabPaymentMethod>(
              value: method,
              activeColor: AppColors.patientPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
