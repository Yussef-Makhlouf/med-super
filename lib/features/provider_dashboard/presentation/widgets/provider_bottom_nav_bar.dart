import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/color_schemes.dart';

/// Shared 4-tab bottom navigation bar for provider screens.
/// Used both inside [ProviderShellScreen] (via [StatefulNavigationShell])
/// and standalone on screens reached outside the shell (e.g. notifications),
/// where [onDestinationSelected] should navigate with `context.go`.
class ProviderBottomNavBar extends StatelessWidget {
  const ProviderBottomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _tabs = [
    _Tab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      labelKey: 'nav.provider_home',
      fallbackLabel: 'الرئيسية',
    ),
    _Tab(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      labelKey: 'nav.provider_appointments',
      fallbackLabel: 'المواعيد',
    ),
    _Tab(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      labelKey: 'nav.provider_patients',
      fallbackLabel: 'المرضى',
    ),
    _Tab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: 'nav.provider_profile',
      fallbackLabel: 'الملف الشخصي',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: Colors.black12,
      indicatorColor: brandBlue.withValues(alpha: 0.12),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: _tabs.map((t) {
        final label = t.labelKey.tr();
        final text = label == t.labelKey ? t.fallbackLabel : label;
        return NavigationDestination(
          icon: Icon(t.icon, color: const Color(0xFF6B7280)),
          selectedIcon: Icon(t.activeIcon, color: brandBlue),
          label: text,
        );
      }).toList(),
    );
  }
}

class _Tab {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.fallbackLabel,
  });

  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final String fallbackLabel;
}
