import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';

/// Short branded bridge between the platform launch window and the routed UI.
/// It never owns startup work; authentication and router initialization continue
/// behind the curtain while the first Flutter frame is presented.
class AppLaunchSplash extends StatefulWidget {
  const AppLaunchSplash({required this.child, super.key});

  final Widget child;

  @override
  State<AppLaunchSplash> createState() => _AppLaunchSplashState();
}

class _AppLaunchSplashState extends State<AppLaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _artOpacity;
  late final Animation<double> _artScale;
  bool _showCurtain = true;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    final entrance = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );
    _artOpacity = entrance;
    _artScale = Tween<double>(begin: 0.88, end: 1).animate(entrance);

    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _showCurtain = false;
    } else {
      _intro.forward();
      Timer(const Duration(milliseconds: 920), () {
        if (!mounted) return;
        setState(() => _fading = true);
        Timer(const Duration(milliseconds: 320), () {
          if (mounted) setState(() => _showCurtain = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showCurtain)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: AbsorbPointer(
                child: Semantics(
                  liveRegion: true,
                  label: 'splash.accessibility'.tr(),
                  child: ExcludeSemantics(child: _buildSplash(context)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplash(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final artHeight = (size.height * 0.38).clamp(220.0, 360.0).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: const Color(0xFF163B9E),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.12),
            radius: 0.9,
            colors: [Color(0xFF2A59C4), Color(0xFF163B9E), Color(0xFF102D78)],
            stops: [0, 0.62, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _intro,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/splash_orbit.png',
                    width: 252,
                    height: artHeight,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MedSuper',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'splash.tagline'.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 38,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Color(0x4DFFFFFF),
                        valueColor: AlwaysStoppedAnimation(
                          AppPalette.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              builder: (context, child) => Opacity(
                opacity: _artOpacity.value,
                child: Transform.scale(scale: _artScale.value, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
