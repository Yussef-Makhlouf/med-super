import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/notifications/presentation/widgets/notification_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_bottom_nav_bar.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

const _kProviderTabPaths = [
  '/provider/home',
  '/provider/appointments',
  '/provider/patients',
  '/provider/profile',
];

class ProviderNotificationsScreen extends ConsumerWidget {
  const ProviderNotificationsScreen({super.key});

  Future<void> _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (notification.isUnread) {
      await ref
          .read(notificationListControllerProvider.notifier)
          .markRead(notification.id);
    }

    if (context.mounted &&
        notification.deepLinkRoute != null &&
        notification.deepLinkRoute!.isNotEmpty) {
      context.go(notification.deepLinkRoute!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final listAsync = ref.watch(notificationListControllerProvider);
    final unreadCount = listAsync.maybeWhen(
      data: (state) => state.items.where((n) => n.isUnread).length,
      orElse: () => 0,
    );
    final avatarUrl = ref.watch(providerHeaderAvatarUrlProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      bottomNavigationBar: ProviderBottomNavBar(
        selectedIndex: 0,
        onDestinationSelected: (index) => context.go(_kProviderTabPaths[index]),
      ),
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'notifications.title'.tr(),
            unreadNotificationsCount: unreadCount,
            avatarUrl: avatarUrl,
          ),
          Expanded(
            child: AsyncValueView<NotificationListState>(
              value: listAsync,
              loadingWidget: const CardSkeletonList(count: 3),
              onRetry: () =>
                  ref.read(notificationListControllerProvider.notifier).refresh(),
              data: (state) {
                if (state.items.isEmpty) {
                  return Center(
                    child: EmptyState(
                      title: 'notifications.empty_title'.tr(),
                      subtitle: 'notifications.empty_subtitle'.tr(),
                      icon: Icons.notifications_none_rounded,
                    ),
                  );
                }

                final grouped = _groupByDay(state.items, textTheme);

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final entry in grouped.entries) ...[
                      Text(
                        entry.key,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final notification in entry.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () =>
                                _onNotificationTap(context, ref, notification),
                            borderRadius: BorderRadius.circular(20),
                            child: NotificationCard(
                              notification: notification,
                              compact: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (state.hasMore)
                      Center(
                        child: state.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: () => ref
                                    .read(
                                      notificationListControllerProvider
                                          .notifier,
                                    )
                                    .loadMore(),
                                child: Text('notifications.load_more'.tr()),
                              ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<AppNotification>> _groupByDay(
    List<AppNotification> items,
    TextTheme textTheme,
  ) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final item in items) {
      final local = item.createdAt.toLocal();
      if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day) {
        today.add(item);
      } else {
        earlier.add(item);
      }
    }

    final result = <String, List<AppNotification>>{};
    if (today.isNotEmpty) {
      result['notifications.today'.tr()] = today;
    }
    if (earlier.isNotEmpty) {
      result['notifications.earlier'.tr()] = earlier;
    }
    return result;
  }
}
