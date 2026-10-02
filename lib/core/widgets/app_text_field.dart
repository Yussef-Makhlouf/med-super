import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.suffix,
    this.prefix,
    this.readOnly = false,
    this.focusNode,
    this.validator,
    this.textDirection,
    this.textAlign,
    this.textStyle,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final Widget? prefix;
  final bool readOnly;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  /// Overrides the default RTL text direction — for fields whose content is
  /// always Western/numeric regardless of locale (phone numbers, country/
  /// region codes, fees, timezones).
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextStyle? textStyle;

  static const _readOnlyBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFFE2E5EA)),
  );

  @override
  Widget build(BuildContext context) {
    final isPhoneField = keyboardType == TextInputType.phone;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: textStyle,
      autofocus: autofocus,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      // A read-only field must not look or behave like an editable one: no
      // focus, no caret, no keyboard.
      canRequestFocus: !readOnly,
      enableInteractiveSelection: !readOnly,
      mouseCursor: readOnly ? SystemMouseCursors.forbidden : null,
      focusNode: focusNode,
      validator: validator,
      // Phone values are LTR even inside the Arabic/RTL app. Letting them
      // inherit RTL can visually move a leading '+' to the end of the number.
      textDirection:
          textDirection ??
          (isPhoneField ? TextDirection.ltr : TextDirection.rtl),
      textAlign: textAlign ?? (isPhoneField ? TextAlign.left : TextAlign.start),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon:
            suffix ??
            (readOnly
                ? const Icon(Icons.lock_outline_rounded, size: 20)
                : null),
        prefixIcon: prefix,
        filled: readOnly ? true : null,
        fillColor: readOnly ? const Color(0xFFF1F3F6) : null,
        border: readOnly ? _readOnlyBorder : null,
        enabledBorder: readOnly ? _readOnlyBorder : null,
        focusedBorder: readOnly ? _readOnlyBorder : null,
        counterText: '',
        // Prevents the label from floating up as garbled characters on web
        // RTL builds — keeps it always inline until focused/filled.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: true,
      ),
    );
  }
}
