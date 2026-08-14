import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_notification.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_bottom_nav_bar.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

const _kProviderTabPaths = [
  '/provider/home',
  '/provider/appointments',
  '/provider/patients',
  '/provider/profile',
];

/// Provider Notifications Screen matching mockup `notifications.png`.
class ProviderNotificationsScreen extends ConsumerWidget {
  const ProviderNotificationsScreen({super.key});

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    DoctorNotification notification,
  ) async {
    if (notification.isUnread) {
      final useCase = ref.read(markNotificationReadUseCaseProvider);
      await useCase.call(notification.id);
      ref.invalidate(doctorNotificationsProvider);
    }

    if (context.mounted &&
        notification.deepLinkRoute != null &&
        notification.deepLinkRoute!.isNotEmpty) {
      // `go` (not `push`) — the target is a shell-branch route already
      // mounted by the persistent StatefulShellRoute; pushing it from this
      // top-level route creates a duplicate Navigator page key.
      context.go(notification.deepLinkRoute!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notificationsAsync = ref.watch(doctorNotificationsProvider);

    final unreadCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => n.isUnread).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      bottomNavigationBar: ProviderBottomNavBar(
        selectedIndex: 0,
        onDestinationSelected: (index) => context.go(_kProviderTabPaths[index]),
      ),
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'التنبيهات',
            unreadNotificationsCount: unreadCount,
          ),
          Expanded(
            child: AsyncValueView<List<DoctorNotification>>(
              value: notificationsAsync,
              loadingWidget: const CardSkeletonList(count: 3),
              onRetry: () => ref.invalidate(doctorNotificationsProvider),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      title: 'لا توجد تنبيهات',
                      subtitle: 'ليس لديك أي تنبيهات حالياً.',
                      icon: Icons.notifications_none_rounded,
                    ),
                  );
                }

                final now = DateTime.now();
                final todayItems = items.where((n) {
                  final dt = n.createdAt.toLocal();
                  return dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day;
                }).toList();

                final earlierItems = items.where((n) {
                  final dt = n.createdAt.toLocal();
                  return !(dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (todayItems.isNotEmpty) ...[
                      _buildSectionHeader('اليوم', textTheme),
                      const SizedBox(height: 12),
                      ...todayItems.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _onNotificationTap(context, ref, n),
                            borderRadius: BorderRadius.circular(20),
                            child: _buildNotificationCard(n),
                          ),
                        ),
                      ),
                    ],
                    if (earlierItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('في وقت سابق', textTheme),
                      const SizedBox(height: 12),
                      ...earlierItems.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _onNotificationTap(context, ref, n),
                            borderRadius: BorderRadius.circular(20),
                            child: _buildNotificationCard(n),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink900,
      ),
    );
  }

  Widget _buildNotificationCard(DoctorNotification notification) {
    final (icon, iconBg, iconColor) = switch (notification.type) {
      NotificationType.newBookingRequest => (
        Icons.calendar_month,
        const Color(0xFFDBEAFE),
        brandBlue,
      ),
      NotificationType.appointmentConfirmed => (
        Icons.calendar_today_outlined,
        const Color(0xFFA7F3D0),
        const Color(0xFF059669),
      ),
      NotificationType.labReportReady => (
        Icons.science_outlined,
        const Color(0xFFFFEDD5),
        const Color(0xFFEA580C),
      ),
      NotificationType.reminder => (
        Icons.notifications_none_rounded,
        const Color(0xFFE2E8F0),
        const Color(0xFF64748B),
      ),
    };

    final timeFormatted = _formatTimeAgo(notification.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.ink900,
                      ),
                    ),
                    Text(
                      timeFormatted,
                      style: const TextStyle(
                        color: AppColors.mutedText2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText2,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (notification.isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: brandBlue,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'أمس';
    }
  }
}
