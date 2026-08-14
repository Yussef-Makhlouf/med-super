import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePlaceholderScreen extends ConsumerWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final user = session?.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('profile.title'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) ...[
              Text(
                user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!
                    : 'profile.guest_name'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1A2B4A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.phone,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: brandBlue),
              ),
              const SizedBox(height: 4),
              Text(
                user.activeRole.apiValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8A94A6),
                ),
              ),
              if (session?.onboardingComplete == false) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.push('/onboarding'),
                  child: Text('profile.complete_profile'.tr()),
                ),
              ],
            ] else
              Text(
                'profile.sprint_note'.tr(),
                style: const TextStyle(color: Color(0xFF8A94A6)),
              ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(sessionControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text('profile.logout'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
