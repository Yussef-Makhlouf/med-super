import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Egypt phone-number field shared by every auth screen that collects a
/// phone number (send-OTP, phone+password login, forgot-password) — a
/// bordered row with a country-code suffix. Each caller supplies its own
/// [validator] so phone-format rules stay with the screen, not this widget.
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    required this.controller,
    required this.validator,
    this.textInputAction = TextInputAction.done,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : AppPalette.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      textInputAction: textInputAction,
                      textAlign: TextAlign.start,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: field.didChange,
                      decoration: InputDecoration(
                        hintText: 'auth.phone_hint'.tr(),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppPalette.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'auth.country_code'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🇪🇬', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
