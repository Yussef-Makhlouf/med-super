import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/core/widgets/app_text_field.dart';

/// Owns the four controllers behind [PaymentCustomerFields] so a checkout
/// screen doesn't have to declare and dispose them one by one.
class PaymentCustomerFormControllers {
  PaymentCustomerFormControllers({String? phone})
    : phone = TextEditingController(text: phone ?? '');

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final TextEditingController phone;

  PaymentCustomerInfo toCustomerInfo() => PaymentCustomerInfo(
    firstName: firstName.text.trim(),
    lastName: lastName.text.trim(),
    email: email.text.trim(),
    phone: phone.text.trim(),
  );

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
  }
}

/// The billing details every online payment needs
/// ([PaymentCustomerInfo]) — shared by wallet top-up and appointment
/// online payment so the two checkouts validate identically.
///
/// Must be placed inside a [Form]; the parent owns the key and calls
/// `validate()` before submitting.
class PaymentCustomerFields extends StatelessWidget {
  const PaymentCustomerFields({required this.controllers, super.key});

  final PaymentCustomerFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'payments.first_name'.tr(),
          controller: controllers.firstName,
          textInputAction: TextInputAction.next,
          maxLength: 100,
          validator: _required,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'payments.last_name'.tr(),
          controller: controllers.lastName,
          textInputAction: TextInputAction.next,
          maxLength: 100,
          validator: _required,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'payments.email'.tr(),
          controller: controllers.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _email,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'payments.phone'.tr(),
          controller: controllers.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          maxLength: 20,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          validator: _required,
        ),
      ],
    );
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty)
      ? 'payments.required_field'.tr()
      : null;

  /// Mirrors the backend's `@IsEmail()` loosely — enough to catch a typo
  /// before a round trip, not a second source of truth for what's valid.
  static String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'payments.required_field'.tr();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
        ? null
        : 'payments.invalid_email'.tr();
  }
}
