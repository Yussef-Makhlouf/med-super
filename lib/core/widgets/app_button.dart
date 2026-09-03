import 'package:flutter/material.dart';

enum _AppButtonVariant { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required this._variant,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  factory AppButton.filled({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    Key? key,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.filled,
        isLoading: isLoading,
        icon: icon,
        key: key,
      );

  factory AppButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    Key? key,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.outlined,
        isLoading: isLoading,
        icon: icon,
        key: key,
      );

  factory AppButton.text({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    Key? key,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.text,
        key: key,
      );

  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant _variant;
  final bool isLoading;
  final Widget? icon;

  Widget get _child => isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : (icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [icon!, const SizedBox(width: 8), Text(label)],
            )
          : Text(label));

  @override
  Widget build(BuildContext context) => switch (_variant) {
        _AppButtonVariant.filled => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _child,
          ),
        _AppButtonVariant.outlined => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _child,
          ),
        _AppButtonVariant.text => TextButton(
            onPressed: onPressed,
            child: _child,
          ),
      };
}
