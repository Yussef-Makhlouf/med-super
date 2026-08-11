import 'package:flutter/material.dart';

enum _AppButtonVariant { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required this._variant,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.fullWidth = false,
    super.key,
  });

  factory AppButton.filled({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    bool fullWidth = false,
    Key? key,
  }) => AppButton._(
    label: label,
    onPressed: onPressed,
    variant: _AppButtonVariant.filled,
    isLoading: isLoading,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    borderRadius: borderRadius,
    fullWidth: fullWidth,
    key: key,
  );

  factory AppButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    Color? foregroundColor,
    double? borderRadius,
    bool fullWidth = false,
    Key? key,
  }) => AppButton._(
    label: label,
    onPressed: onPressed,
    variant: _AppButtonVariant.outlined,
    isLoading: isLoading,
    icon: icon,
    foregroundColor: foregroundColor,
    borderRadius: borderRadius,
    fullWidth: fullWidth,
    key: key,
  );

  factory AppButton.text({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    Key? key,
  }) => AppButton._(
    label: label,
    onPressed: onPressed,
    variant: _AppButtonVariant.text,
    icon: icon,
    key: key,
  );

  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant _variant;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final bool fullWidth;

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

  Size? get _minimumSize => fullWidth ? const Size(double.infinity, 52) : null;

  ButtonStyle? get _filledStyle =>
      (backgroundColor == null &&
          foregroundColor == null &&
          borderRadius == null &&
          !fullWidth)
      ? null
      : ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          minimumSize: _minimumSize,
          shape: borderRadius == null
              ? null
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                ),
        );

  ButtonStyle? get _outlinedStyle =>
      (foregroundColor == null && borderRadius == null && !fullWidth)
      ? null
      : OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          minimumSize: _minimumSize,
          side: foregroundColor == null
              ? null
              : BorderSide(color: foregroundColor!),
          shape: borderRadius == null
              ? null
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                ),
        );

  @override
  Widget build(BuildContext context) => switch (_variant) {
    _AppButtonVariant.filled => ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _filledStyle,
      child: _child,
    ),
    _AppButtonVariant.outlined => OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: _outlinedStyle,
      child: _child,
    ),
    _AppButtonVariant.text => TextButton(onPressed: onPressed, child: _child),
  };
}
