import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/core/payments/presentation/widgets/payment_customer_fields.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';

/// Collects the billing details Paymob requires before an online payment is
/// initiated, returning null if the patient backs out.
Future<PaymentCustomerInfo?> showPaymentCustomerSheet(
  BuildContext context, {
  String? initialPhone,
}) {
  return showModalBottomSheet<PaymentCustomerInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PaymentCustomerSheet(initialPhone: initialPhone),
  );
}

class _PaymentCustomerSheet extends StatefulWidget {
  const _PaymentCustomerSheet({this.initialPhone});

  final String? initialPhone;

  @override
  State<_PaymentCustomerSheet> createState() => _PaymentCustomerSheetState();
}

class _PaymentCustomerSheetState extends State<_PaymentCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final PaymentCustomerFormControllers _controllers =
      PaymentCustomerFormControllers(phone: widget.initialPhone);

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controllers.toCustomerInfo());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'payments.customer_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'payments.customer_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText2,
                ),
              ),
              const SizedBox(height: 20),
              PaymentCustomerFields(controllers: _controllers),
              const SizedBox(height: 20),
              AppButton.filled(
                label: 'payments.continue_to_payment'.tr(),
                fullWidth: true,
                borderRadius: 16,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
