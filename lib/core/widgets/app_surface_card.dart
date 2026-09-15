import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';

/// The one elevated-card shape for the app (design system v2).
///
/// Extracted from a pattern that had drifted into three near-identical but
/// inconsistent private implementations (`doctor_details_screen.dart` and
/// `clinic_branch_details_screen.dart` each had their own `_Card` with a
/// different shadow literal; `booking_confirm_screen.dart` and
/// `appointment_detail_screen.dart` used a border instead of a shadow
/// entirely). White surface, `AppRadii.lg` corners, `AppShadows.resting`
/// elevation, 16px padding by default — every card in the app should look
/// like this one unless it has a specific reason not to.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.resting,
      ),
      child: child,
    );
  }
}
