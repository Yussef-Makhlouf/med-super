import 'package:flutter/material.dart';

/// Wraps [child] with a tactile press-down effect (scales to [scale] while
/// held) so taps feel physical instead of relying on the default Material
/// ripple alone.
///
/// Built on `InkWell` (ripple painted transparent) rather than a bare
/// `GestureDetector` so the target keeps standard button semantics, focus
/// traversal, and keyboard activation (Enter/Space) for free — a plain
/// `GestureDetector` looks identical but is invisible to a screen reader and
/// unreachable by keyboard, which matters on desktop builds of this app.
class TapScale extends StatefulWidget {
  const TapScale({
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        borderRadius: widget.borderRadius,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
