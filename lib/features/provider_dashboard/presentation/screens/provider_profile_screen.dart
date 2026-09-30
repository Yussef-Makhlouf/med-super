import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/avatar_image.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/core/widgets/app_nav_icons.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_clinic_settings_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_edit_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_schedule_editor_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_dashboard_screen.dart';

/// Role-aware account and workspace settings for doctors and clinic assistants.
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionControllerProvider).asData?.value;

    final isAssistant = session?.user.isAssistant ?? false;
    final doctorAccountAsync = isAssistant
        ? null
        : ref.watch(doctorAccountProvider);

    // The assistant identity comes from the active session. The provider
    // account endpoint resolves to the supervising doctor for assistant
    // sessions, so never use its name or portrait as the assistant's own.
    final displayName = isAssistant
        ? (session?.user.displayName ??
              'provider_dashboard.profile.assistant_fallback'.tr())
        : doctorAccountAsync?.maybeWhen(
                data: (acc) => acc.name,
                orElse: () =>
                    session?.user.displayName ??
                    'provider_dashboard.profile.doctor_fallback'.tr(),
              ) ??
              'provider_dashboard.profile.doctor_fallback'.tr();

    final doctorName = displayName;

    // No clinic-affiliation join exists on `GET /v1/doctors/me`
    // (`clinic-reservations` File 12 Part 45) — showing a hospital name here
    // would mean fabricating data, so this line is specialty-only now.
    final subtitle = isAssistant
        ? 'provider_dashboard.profile.assistant_role'.tr()
        : doctorAccountAsync?.maybeWhen(
                data: (acc) => acc.specialty,
                orElse: () => '',
              ) ??
              '';

    final avatarUrl = isAssistant
        ? null
        : doctorAccountAsync?.maybeWhen(
            data: (acc) => acc.avatarUrl,
            orElse: () => null,
          );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'provider_dashboard.profile.title'.tr(),
            avatarUrl: avatarUrl,
            onAvatarTap: () {}, // already on the profile screen
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Centered Avatar with edit pencil badge
                  Center(
                    child: Semantics(
                      button: !isAssistant,
                      label: isAssistant
                          ? displayName
                          : 'provider_dashboard.profile.edit_profile'.tr(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isAssistant
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ProviderEditProfileScreen(),
                                ),
                              ),
                        child: Stack(
                          children: [
                            AvatarCircle(
                              radius: 55,
                              backgroundColor: AppColors.surfaceCard,
                              imageUrl: avatarUrl,
                              placeholderIcon: SolarIconsBold.userCircle,
                              placeholderIconColor: AppColors.mutedText,
                            ),
                            if (!isAssistant)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: brandBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    SolarIconsOutline.pen,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctorName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Assistant workspace actions are scoped to assigned
                  // branches by the backend.
                  if (isAssistant) const _AssistantAppointmentsClinicTabs(),
                  // Navigation Options List
                  if (!isAssistant)
                    buildNavTile(
                      context: context,
                      icon: SolarIconsOutline.user,
                      iconColor: brandBlue,
                      title: 'provider_dashboard.profile.personal_info'.tr(),
                      subtitle: 'provider_dashboard.profile.personal_info_hint'
                          .tr(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderEditProfileScreen(),
                        ),
                      ),
                    ),
                  // Doctor-only tiles — hidden from assistants
                  if (!isAssistant) ...[
                    const SizedBox(height: 14),
                    buildNavTile(
                      context: context,
                      icon: SolarIconsOutline.buildings,
                      iconColor: const Color(0xFF10B981),
                      title: 'provider_dashboard.profile.clinic_settings'.tr(),
                      subtitle:
                          'provider_dashboard.profile.clinic_settings_hint'
                              .tr(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderClinicSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    buildNavTile(
                      context: context,
                      icon: SolarIconsOutline.calendar,
                      iconColor: const Color(0xFFA855F7),
                      title: 'provider_dashboard.profile.schedule'.tr(),
                      subtitle: 'provider_dashboard.profile.schedule_hint'.tr(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderScheduleEditorScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    buildNavTile(
                      context: context,
                      icon: SolarIconsOutline.walletMoney,
                      iconColor: brandBlue,
                      title: 'provider_dashboard.profile.wallet'.tr(),
                      subtitle: 'provider_dashboard.profile.wallet_hint'.tr(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(
                            name: WalletDashboardScreen.routeName,
                          ),
                          builder: (_) => const WalletDashboardScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Doctor-only: manage clinic assistants
                    buildNavTile(
                      context: context,
                      icon: SolarIconsOutline.diploma,
                      iconColor: const Color(0xFFF97316),
                      title: 'assistants.title'.tr(),
                      subtitle: 'assistants.manage_subtitle'.tr(),
                      onTap: () => context.push('/provider/assistants'),
                    ),
                  ],
                  const SizedBox(height: 36),
                  // Logout button — AppButton.outlined, same as every other
                  // action button across the provider dashboard screens.
                  AppButton.outlined(
                    label: 'profile.logout'.tr(),
                    icon: const Icon(SolarIconsOutline.logout, size: 20),
                    foregroundColor: const Color(0xFFDC2626),
                    borderRadius: AppRadii.pill,
                    fullWidth: true,
                    onPressed: () async {
                      // '/account-login' (phone+password), not '/login'
                      // (OTP first-time signup) — same reasoning as the
                      // patient profile's logout button. Must be awaited: an
                      // un-awaited logout races the router's own
                      // sessionControllerProvider-driven redirect, which can
                      // send the user straight back into /provider/home
                      // before the session is actually cleared.
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .logout();
                      if (!context.mounted) return;
                      context.go('/account-login');
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'provider_dashboard.profile.footer'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildNavTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.resting,
          ),
          child: Row(
            children: [
              AppIconTile(icon: icon, color: iconColor, size: 48, iconSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppNavIcons.chevronForward(context),
                color: AppColors.mutedText2,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Assistant-only workspace controls. The backend scopes these routes to the
/// branches assigned to the active assistant.
class _AssistantAppointmentsClinicTabs extends StatelessWidget {
  const _AssistantAppointmentsClinicTabs();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProviderProfileScreen.buildNavTile(
          context: context,
          icon: SolarIconsOutline.calendar,
          iconColor: const Color(0xFFA855F7),
          title: 'provider_dashboard.profile.schedule'.tr(),
          subtitle: 'provider_dashboard.profile.assistant_schedule_hint'.tr(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProviderScheduleEditorScreen(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ProviderProfileScreen.buildNavTile(
          context: context,
          icon: SolarIconsOutline.buildings,
          iconColor: const Color(0xFF10B981),
          title: 'provider_dashboard.profile.assigned_branches'.tr(),
          subtitle: 'provider_dashboard.profile.assigned_branches_hint'.tr(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProviderClinicSettingsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
