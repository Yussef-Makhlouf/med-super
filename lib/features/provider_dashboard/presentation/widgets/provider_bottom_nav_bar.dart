import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:solar_icons/solar_icons.dart';

/// Shared 4-tab bottom navigation bar for provider screens (design system
/// v2) — a floating elevated card with tinted-pill active states, replacing
/// the stock Material `NavigationBar` this used to restyle rather than
/// redesign.
///
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
      icon: SolarIconsOutline.home,
      activeIcon: SolarIconsBold.home,
      labelKey: 'nav.provider_home',
      fallbackLabel: 'الرئيسية',
    ),
    _Tab(
      icon: SolarIconsOutline.calendar,
      activeIcon: SolarIconsBold.calendar,
      labelKey: 'nav.provider_appointments',
      fallbackLabel: 'المواعيد',
    ),
    _Tab(
      icon: SolarIconsOutline.usersGroupRounded,
      activeIcon: SolarIconsBold.usersGroupRounded,
      labelKey: 'nav.provider_patients',
      fallbackLabel: 'المرضى',
    ),
    _Tab(
      icon: SolarIconsOutline.userCircle,
      activeIcon: SolarIconsBold.userCircle,
      labelKey: 'nav.provider_profile',
      fallbackLabel: 'الملف الشخصي',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _NavBarItem(
                  tab: _tabs[i],
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
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

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tab.labelKey.tr();
    final text = label == tab.labelKey ? tab.fallbackLabel : label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? brandBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? tab.activeIcon : tab.icon,
              size: 24,
              color: selected ? brandBlue : AppColors.mutedText2,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? brandBlue : AppColors.mutedText2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
