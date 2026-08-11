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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 20,
            left: 32,
            right: 32,
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
              top: 20,
              right: 32,
              left: 32,
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
            children: List.generate(stepLabels.length, (index) {
              final isActive = index == currentStep;
              final isDone = index < currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isDone ? accentColor : _inactiveBg,
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
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isActive || isDone
                                    ? Colors.white
                                    : _inactiveText,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stepLabels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive ? accentColor : _inactiveText,
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
  }
}
