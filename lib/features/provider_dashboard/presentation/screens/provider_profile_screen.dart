import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/avatar_image.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_clinic_settings_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_edit_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_schedule_editor_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_security_privacy_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// Provider Profile Screen pixel-perfect against mockup `profile.png`.
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final doctorAccountAsync = ref.watch(doctorAccountProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;

    final doctorName = doctorAccountAsync.maybeWhen(
      data: (acc) => acc.name,
      orElse: () => session?.user.displayName ?? 'د. أحمد علي',
    );

    final hospitalName = doctorAccountAsync.maybeWhen(
      data: (acc) => '${acc.hospitalName} • ${acc.specialty}',
      orElse: () => 'مستشفى الملك فيصل التخصصي',
    );

    final avatarUrl = doctorAccountAsync.maybeWhen(
      data: (acc) => acc.avatarUrl,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'الملف الشخصي',
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
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderEditProfileScreen(),
                        ),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppColors.surfaceCard,
                            backgroundImage: avatarUrl != null
                                ? resolveAvatarImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(
                                    Icons.account_circle,
                                    size: 110,
                                    color: AppColors.mutedText,
                                  )
                                : null,
                          ),
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
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
                    hospitalName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Navigation Options List
                  _buildNavTile(
                    icon: Icons.person_outline,
                    iconBg: brandBlue.withValues(alpha: 0.1),
                    iconColor: brandBlue,
                    title: 'المعلومات الشخصية',
                    subtitle: 'الاسم، التخصص، سنوات الخبرة',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderEditProfileScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavTile(
                    icon: Icons.domain_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'إعدادات العيادة',
                    subtitle: 'العنوان، معلومات الاتصال',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderClinicSettingsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavTile(
                    icon: Icons.calendar_today_outlined,
                    iconBg: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFFA855F7),
                    title: 'جدول المواعيد',
                    subtitle: 'ساعات العمل والحضور',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderScheduleEditorScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNavTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFEF4444),
                    title: 'الأمان والخصوصية',
                    subtitle: 'كلمة المرور، المصادقة الثنائية',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderSecurityPrivacyScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Logout button — AppButton.outlined, same as every other
                  // action button across the provider dashboard screens.
                  AppButton.outlined(
                    label: 'تسجيل الخروج',
                    icon: const Icon(Icons.logout, size: 20),
                    foregroundColor: const Color(0xFFDC2626),
                    borderRadius: 16,
                    fullWidth: true,
                    onPressed: () {
                      ref.read(sessionControllerProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'الإصدار 2.4.0 • تواصل مع الدعم الفني',
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

  static Widget _buildNavTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
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
              const Icon(
                Icons.chevron_left,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
