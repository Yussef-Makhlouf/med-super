import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Loading placeholder for the pharmacy select screen's card list, shown via
/// [AsyncValueView]'s `loadingWidget` while [pharmaciesProvider] resolves.
///
/// Scoped to the card list only — the search bar, filter chips and map
/// render immediately regardless of loading state, so this must not
/// replace them too.
///
/// Explicitly *not* a spinner: a structural skeleton (3 card shapes) that
/// pulses opacity via a repeating [AnimationController] — no new shimmer
/// package dependency, matching the "keep it dependency-free" requirement
/// for this screen.
class PharmacySearchSkeleton extends StatefulWidget {
  const PharmacySearchSkeleton({super.key});

  @override
  State<PharmacySearchSkeleton> createState() => _PharmacySearchSkeletonState();
}

class _PharmacySearchSkeletonState extends State<PharmacySearchSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block({double? width, double height = 14, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _cardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _block(width: 120, height: 16),
                    const SizedBox(height: 8),
                    _block(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _block(width: 60, height: 12),
              const SizedBox(width: 12),
              _block(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 10),
          _block(width: 140, height: 12),
          const SizedBox(height: 14),
          _block(height: 44, radius: AppRadii.xl),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          // This placeholder stands in for the real card list, which lives
          // inside a scrolling ListView — a plain Column here would instead
          // be forced to fit its parent's height and overflow once the 3
          // card skeletons exceed it (e.g. on narrower/shorter viewports).
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _cardSkeleton(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
