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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      focusNode: focusNode,
      validator: validator,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffix,
        prefixIcon: prefix,
        counterText: '',
        // Prevents the label from floating up as garbled characters on web
        // RTL builds — keeps it always inline until focused/filled.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: true,
      ),
    );
  }
}
