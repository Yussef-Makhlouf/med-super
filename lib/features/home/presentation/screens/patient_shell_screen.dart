import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';

/// Bottom-tab shell for the patient flavor (Figma: 5 tabs).
class PatientShellScreen extends StatelessWidget {
  const PatientShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static final _tabs = [
    _Tab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      labelKey: 'nav.home',
    ),
    _Tab(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      labelKey: 'nav.appointments',
    ),
    _Tab(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      labelKey: 'nav.orders',
    ),
    _Tab(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      labelKey: 'nav.notifications',
    ),
    _Tab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: 'nav.profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: brandBlue.withValues(alpha: 0.12),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: const Color(0xFF6B7280)),
                selectedIcon: Icon(t.activeIcon, color: brandBlue),
                label: t.labelKey.tr(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });

  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
}
