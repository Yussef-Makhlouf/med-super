import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:solar_icons/solar_icons.dart';

/// One elevated header surface for a multi-step booking flow — back button
/// + centered title, and (when [stepLabels] is given) the step progress
/// tracker underneath, all inside a single white card with real depth.
///
/// Replaces the "flat title bar stacked on top of a flat StepProgressHeader"
/// pattern duplicated across the lab/pharmacy booking flows: two
/// disconnected bars become one designed unit instead of two.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    required this.title,
    required this.onBack,
    this.stepLabels,
    this.currentStep,
    this.accentColor = AppPalette.primary,
    super.key,
  }) : assert(
         (stepLabels == null) == (currentStep == null),
         'stepLabels and currentStep must both be set or both be omitted',
       );

  final String title;
  final VoidCallback onBack;
  final List<String>? stepLabels;
  final int? currentStep;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final labels = stepLabels;
    final step = currentStep;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xl),
        ),
        boxShadow: AppShadows.resting,
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(SolarIconsOutline.arrowRight),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          if (labels != null && step != null) ...[
            const SizedBox(height: 12),
            StepProgressHeader(
              stepLabels: labels,
              currentStep: step,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}
