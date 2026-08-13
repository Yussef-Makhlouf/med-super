import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_bottom_nav_bar.dart';

/// 4-tab shell for the provider dashboard:
/// 1. الرئيسية (Home / Dashboard)
/// 2. المواعيد (Appointments)
/// 3. المرضى (Patients)
/// 4. الملف الشخصي (Profile)
class ProviderShellScreen extends StatelessWidget {
  const ProviderShellScreen({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ProviderBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
