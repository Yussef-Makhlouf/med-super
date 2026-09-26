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

  TextStyle _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
        fontSize: _variant == _AppButtonVariant.text ? 15 : 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  Widget _child(BuildContext context) => isLoading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: switch (_variant) {
              _AppButtonVariant.filled =>
                foregroundColor ??
                    (backgroundColor == null
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.white),
              _AppButtonVariant.outlined || _AppButtonVariant.text =>
                foregroundColor ?? Theme.of(context).colorScheme.primary,
            },
          ),
        )
      : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: _labelStyle(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(label, style: _labelStyle(context)));

  Size? get _minimumSize => fullWidth ? const Size(double.infinity, 56) : null;

  ButtonStyle? get _filledStyle =>
      (backgroundColor == null &&
          foregroundColor == null &&
          borderRadius == null &&
          !fullWidth)
      ? null
      : ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          // When a custom backgroundColor is set, default the text/icon to white
          // so it stays legible on any coloured background (Material3 otherwise
          // falls back to colorScheme.onSurface which may be dark on a dark bg).
          foregroundColor:
              foregroundColor ??
              (backgroundColor != null ? Colors.white : null),
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
      child: _child(context),
    ),
    _AppButtonVariant.outlined => OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: _outlinedStyle,
      child: _child(context),
    ),
    _AppButtonVariant.text => TextButton(
      onPressed: onPressed,
      child: _child(context),
    ),
  };
}
