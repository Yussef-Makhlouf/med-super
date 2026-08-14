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
    required this.branchNavigatorKeys,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// One key per branch, in branch order — lets re-tapping the active tab
  /// pop any screen pushed imperatively (via `Navigator.push`) on top of
  /// that branch back to its root, since `goBranch` alone can't see those.
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  void _onDestinationSelected(int index) {
    if (index == navigationShell.currentIndex) {
      branchNavigatorKeys[index].currentState?.popUntil(
        (route) => route.isFirst,
      );
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ProviderBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
