import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fades and slides [child] in once, with a delay proportional to [index].
///
/// Used to reveal a screen's sections/list items in reading order on first
/// build — a single motivated entrance, not a decorative loop. Respects
/// the platform's reduce-motion setting by rendering [child] immediately
/// with no animation.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
    super.key,
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    final reduceMotion = SchedulerBinding.instance.platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.baseDelay * widget.index, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
