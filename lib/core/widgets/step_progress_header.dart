import 'package:flutter/material.dart';

/// Circular multi-step progress indicator matching the Figma stepper used
/// by both the Lab Booking (3 steps) and Doctor Registration (4 steps) flows.
/// Steps render right-to-left visually (RTL), driven logically left-to-right
/// in [stepLabels] (index 0 = first step).
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    required this.stepLabels,
    required this.currentStep,
    required this.accentColor,
    super.key,
  });

  final List<String> stepLabels;

  /// 0-indexed.
  final int currentStep;
  final Color accentColor;

  static const _inactiveBg = Color(0xFFECEEF0);
  static const _inactiveBorder = Color(0xFFE0E3E5);
  static const _inactiveText = Color(0xFF737686);
  static const _trackBg = Color(0xFFECEEF0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the circle/label continuously with the available per-step
        // width, instead of a single breakpoint, so `stepLabels.length`
        // columns keep shrinking gracefully as the screen gets narrower
        // rather than jumping straight from "normal" to "compact".
        final horizontalPadding = constraints.maxWidth < 340 ? 8.0 : 16.0;
        final stepWidth =
            (constraints.maxWidth - horizontalPadding * 2) / stepLabels.length;
        final circleSize = (stepWidth * 0.42).clamp(24.0, 40.0).toDouble();
        final fontSize = (stepWidth * 0.135).clamp(9.0, 14.0).toDouble();
        final trackInset = (stepWidth * 0.32).clamp(12.0, 32.0).toDouble();

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: circleSize / 2,
                left: trackInset,
                right: trackInset,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _trackBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              if (currentStep > 0)
                Positioned(
                  top: circleSize / 2,
                  right: trackInset,
                  left: trackInset,
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: stepLabels.length <= 1
                        ? 0
                        : currentStep / (stepLabels.length - 1),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(stepLabels.length, (index) {
                  final isActive = index == currentStep;
                  final isDone = index < currentStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isDone
                                ? accentColor
                                : _inactiveBg,
                            border: isActive || isDone
                                ? null
                                : Border.all(color: _inactiveBorder),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isDone
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: circleSize * 0.45,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: circleSize * 0.5,
                                    fontWeight: FontWeight.w600,
                                    color: isActive || isDone
                                        ? Colors.white
                                        : _inactiveText,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            stepLabels[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive ? accentColor : _inactiveText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
