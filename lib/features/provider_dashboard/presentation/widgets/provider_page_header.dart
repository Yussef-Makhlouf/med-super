import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/utils/avatar_image.dart';

/// Generic header bar for Provider screens (Dashboard, Notifications, Patients).
/// Shows title on the right (RTL), and bell icon + avatar on the left.
class ProviderPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ProviderPageHeader({
    required this.title,
    this.unreadNotificationsCount = 0,
    this.avatarUrl,
    this.onNotificationTap,
    this.onAvatarTap,
    super.key,
  });

  final String title;
  final int unreadNotificationsCount;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // Left: Notification Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.ink700,
                      size: 26,
                    ),
                    onPressed:
                        onNotificationTap ??
                        () => context.go('/provider/notifications'),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              // Center: Screen Title
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
              ),
              // Right: Doctor Avatar
              GestureDetector(
                onTap: onAvatarTap ?? () => context.go('/provider/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceCard,
                  backgroundImage: avatarUrl != null
                      ? resolveAvatarImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.mutedText,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
