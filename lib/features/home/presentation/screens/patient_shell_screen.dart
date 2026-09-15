import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

/// Bottom-tab shell for the patient flavor (5 tabs).
///
/// Fully theme-driven (design system v2) — background, indicator, icon and
/// label colors all come from `NavigationBarThemeData` in `app_theme.dart`,
/// not hardcoded here, so a future palette change needs no edits to this
/// file. Solar icons (Outline/Bold pairing) replace the old Material
/// outline/filled icon pairs.
class PatientShellScreen extends StatelessWidget {
  const PatientShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static final _tabs = [
    _Tab(
      icon: SolarIconsOutline.home,
      activeIcon: SolarIconsBold.home,
      labelKey: 'nav.home',
    ),
    _Tab(
      icon: SolarIconsOutline.calendarMinimalistic,
      activeIcon: SolarIconsBold.calendarMinimalistic,
      labelKey: 'nav.appointments',
    ),
    _Tab(
      icon: SolarIconsOutline.bag2,
      activeIcon: SolarIconsBold.bag2,
      labelKey: 'nav.orders',
    ),
    _Tab(
      icon: SolarIconsOutline.bellBing,
      activeIcon: SolarIconsBold.bellBing,
      labelKey: 'nav.notifications',
    ),
    _Tab(
      icon: SolarIconsOutline.userRounded,
      activeIcon: SolarIconsBold.userRounded,
      labelKey: 'nav.profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Home (index 0) always resets to its root screen, never
          // restoring whatever leaf it was left on — the branch's nested
          // routes (`appointmentRoutes`/`searchRoutes`, e.g. booking
          // confirm/success/doctor-detail) are one-shot flows, not states
          // the Home tab should "remember". Every other tab keeps the
          // normal go_router behavior (only reset on a same-tab re-tap).
          initialLocation:
              index == 0 || index == navigationShell.currentIndex,
        ),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
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
