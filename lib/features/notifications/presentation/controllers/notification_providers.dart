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
      (ref) =>
          MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)),
    );

class NotificationListState {
  const NotificationListState({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<AppNotification> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  NotificationListState copyWith({
    List<AppNotification>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await ref
        .read(listNotificationsUseCaseProvider)
        .call(cursor: current.nextCursor);

    state = result.when(
      ok: (page) => AsyncData(
        NotificationListState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
      ),
      err: (failure) => AsyncData(current.copyWith(isLoadingMore: false)),
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
    for (final notification in unread) {
      await ref.read(markNotificationReadUseCaseProvider).call(notification.id);
    }

    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items) item.copyWith(isUnread: false),
        ],
      ),
    );
  }
}

final notificationListControllerProvider = NotifierProvider<
  NotificationListController,
  AsyncValue<NotificationListState>
>(NotificationListController.new);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationListControllerProvider).maybeWhen(
    data: (state) => state.items.where((n) => n.isUnread).length,
    orElse: () => 0,
  );
});
