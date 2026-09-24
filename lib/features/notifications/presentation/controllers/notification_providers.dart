import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:med_super/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';
import 'package:med_super/features/notifications/domain/usecases/list_notifications_usecase.dart';
import 'package:med_super/features/notifications/domain/usecases/mark_notification_read_usecase.dart';

final notificationRemoteDatasourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
      final session = ref.watch(sessionControllerProvider).asData?.value;
      return NotificationRemoteDatasource(
        ref.watch(dioProvider),
        isProvider: session?.user.isProvider ?? false,
      );
    });

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDatasourceProvider),
  );
});

final listNotificationsUseCaseProvider = Provider<ListNotificationsUseCase>(
  (ref) => ListNotificationsUseCase(ref.watch(notificationRepositoryProvider)),
);

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>(
      (ref) => MarkNotificationReadUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

class NotificationListState {
  const NotificationListState({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<AppNotification> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  NotificationListState copyWith({
    List<AppNotification>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class NotificationListController
    extends Notifier<AsyncValue<NotificationListState>> {
  @override
  AsyncValue<NotificationListState> build() {
    _loadInitial();
    return const AsyncLoading();
  }

  Future<void> _loadInitial() async {
    state = const AsyncLoading();
    final result = await ref.read(listNotificationsUseCaseProvider).call();
    state = result.when(
      ok: (page) => AsyncData(
        NotificationListState(items: page.items, nextCursor: page.nextCursor),
      ),
      err: (failure) => AsyncError(failure, StackTrace.current),
    );
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    final result = await ref
        .read(listNotificationsUseCaseProvider)
        .call(cursor: current.nextCursor);

    state = result.when(
      ok: (page) {
        final seenIds = current.items.map((item) => item.id).toSet();
        final newItems = page.items
            .where((item) => seenIds.add(item.id))
            .toList(growable: false);
        final nextCursor = page.nextCursor == current.nextCursor
            ? null
            : page.nextCursor;
        return AsyncData(
          NotificationListState(
            items: [...current.items, ...newItems],
            nextCursor: nextCursor,
            isLoadingMore: false,
          ),
        );
      },
      err: (failure) => AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      ),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.asData?.value;
    if (current == null) return;

    final result = await ref.read(markNotificationReadUseCaseProvider).call(id);
    if (result case Ok()) {
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              if (item.id == id) item.copyWith(isUnread: false) else item,
          ],
        ),
      );
    }
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value;
    if (current == null) return;

    final unread = current.items.where((n) => n.isUnread).toList();
    final markedReadIds = <String>{};
    for (final notification in unread) {
      final result = await ref
          .read(markNotificationReadUseCaseProvider)
          .call(notification.id);
      if (result case Ok()) markedReadIds.add(notification.id);
    }

    final latest = state.asData?.value ?? current;
    state = AsyncData(
      latest.copyWith(
        items: [
          for (final item in latest.items)
            markedReadIds.contains(item.id)
                ? item.copyWith(isUnread: false)
                : item,
        ],
      ),
    );
  }
}

final notificationListControllerProvider =
    NotifierProvider<
      NotificationListController,
      AsyncValue<NotificationListState>
    >(NotificationListController.new);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationListControllerProvider)
      .maybeWhen(
        data: (state) => state.items.where((n) => n.isUnread).length,
        orElse: () => 0,
      );
});
