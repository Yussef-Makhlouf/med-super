import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/notifications/presentation/widgets/notification_card.dart';

class PatientNotificationsScreen extends ConsumerWidget {
  const PatientNotificationsScreen({super.key});

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (notification.isUnread) {
      await ref
          .read(notificationListControllerProvider.notifier)
          .markRead(notification.id);
    }

    final route = notification.deepLinkRoute;
    if (context.mounted && route != null && route.isNotEmpty) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'profile.guest_name'.tr();
    final listAsync = ref.watch(notificationListControllerProvider);

    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _NotifHeader(displayName: displayName),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TitleRow(
                hasUnread:
                    listAsync.asData?.value.items.any((n) => n.isUnread) ??
                    false,
                onMarkAllRead: () => ref
                    .read(notificationListControllerProvider.notifier)
                    .markAllRead(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncValueView<NotificationListState>(
                value: listAsync,
                loadingWidget: const CardSkeletonList(count: 4),
                onRetry: () => ref
                    .read(notificationListControllerProvider.notifier)
                    .refresh(),
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

                  final grouped = _groupByDay(state.items);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    children: [
                      for (final entry in grouped.entries) ...[
                        _SectionHeader(label: entry.key),
                        const SizedBox(height: 8),
                        for (final notification in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _onTap(context, ref, notification),
                              borderRadius: BorderRadius.circular(16),
                              splashColor: AppPalette.primary.withValues(
                                alpha: 0.06,
                              ),
                              child: NotificationCard(
                                notification: notification,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
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
      ),
    );
  }

  Map<String, List<AppNotification>> _groupByDay(List<AppNotification> items) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final item in items) {
      final local = item.createdAt.toLocal();
      if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day) {
        today.add(item);
      } else if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day - 1) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    final result = <String, List<AppNotification>>{};
    if (today.isNotEmpty) {
      result['notifications.today'.tr()] = today;
    }
    if (yesterday.isNotEmpty) {
      result['notifications.yesterday'.tr()] = yesterday;
    }
    if (earlier.isNotEmpty) {
      result['notifications.earlier'.tr()] = earlier;
    }
    return result;
  }
}

class _NotifHeader extends StatelessWidget {
  const _NotifHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'home.welcome'.tr(),
              style: textTheme.bodyMedium?.copyWith(color: AppPalette.inkMuted),
            ),
            Text(
              displayName,
              style: textTheme.titleMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.hasUnread, required this.onMarkAllRead});

  final bool hasUnread;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          'notifications.title'.tr(),
          style: textTheme.headlineSmall?.copyWith(
            color: AppPalette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (hasUnread)
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.primary,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'notifications.mark_all_read'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: AppPalette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
