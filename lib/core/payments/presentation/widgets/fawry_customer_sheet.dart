import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_super/core/payments/domain/entities/payment_phone_info.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';

/// Collects only the phone number required to create an appointment Fawry
/// reference. Billing name and email are not collected or sent in this flow.
Future<PaymentPhoneInfo?> showFawryCustomerSheet(
  BuildContext context, {
  String? initialPhone,
}) {
  return showModalBottomSheet<PaymentPhoneInfo>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FawryCustomerSheet(initialPhone: initialPhone),
  );
}

class _FawryCustomerSheet extends StatefulWidget {
  const _FawryCustomerSheet({this.initialPhone});

  final String? initialPhone;

  @override
  State<_FawryCustomerSheet> createState() => _FawryCustomerSheetState();
}

class _FawryCustomerSheetState extends State<_FawryCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initialPhone ?? '',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      PaymentPhoneInfo(phone: _phoneController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
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
                'payments.fawry_customer_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText2,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'payments.phone'.tr(),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 20,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'payments.required_field'.tr()
                    : null,
              ),
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
