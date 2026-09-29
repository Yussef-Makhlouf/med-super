import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:med_super/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';
import 'package:med_super/features/notifications/domain/usecases/get_notification_preferences_usecase.dart';
import 'package:med_super/features/notifications/domain/usecases/list_notifications_usecase.dart';
import 'package:med_super/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:med_super/features/notifications/domain/usecases/update_notification_preferences_usecase.dart';

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

final getNotificationPreferencesUseCaseProvider =
    Provider<GetNotificationPreferencesUseCase>(
      (ref) => GetNotificationPreferencesUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

final updateNotificationPreferencesUseCaseProvider =
    Provider<UpdateNotificationPreferencesUseCase>(
      (ref) => UpdateNotificationPreferencesUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

class NotificationPreferencesState {
  const NotificationPreferencesState({
    required this.preferences,
    required this.savedPreferences,
    this.isSaving = false,
    this.saveFailure,
  });

  final List<NotificationPreference> preferences;
  final List<NotificationPreference> savedPreferences;
  final bool isSaving;
  final Object? saveFailure;

  bool get isDirty {
    if (preferences.length != savedPreferences.length) return true;
    for (var i = 0; i < preferences.length; i++) {
      final current = preferences[i];
      final saved = savedPreferences[i];
      if (current.tier != saved.tier ||
          current.channel != saved.channel ||
          current.effectiveEnabled != saved.effectiveEnabled) {
        return true;
      }
    }
    return false;
  }

  NotificationPreferencesState copyWith({
    List<NotificationPreference>? preferences,
    List<NotificationPreference>? savedPreferences,
    bool? isSaving,
    Object? saveFailure,
    bool clearSaveFailure = false,
  }) => NotificationPreferencesState(
    preferences: preferences ?? this.preferences,
    savedPreferences: savedPreferences ?? this.savedPreferences,
    isSaving: isSaving ?? this.isSaving,
    saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
  );
}

class NotificationPreferencesController
    extends Notifier<AsyncValue<NotificationPreferencesState>> {
  @override
  AsyncValue<NotificationPreferencesState> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    final result = await ref
        .read(getNotificationPreferencesUseCaseProvider)
        .call();
    state = result.when(
      ok: (preferences) {
        final safe = List<NotificationPreference>.unmodifiable(preferences);
        return AsyncData(
          NotificationPreferencesState(
            preferences: safe,
            savedPreferences: safe,
          ),
        );
      },
      err: (failure) => AsyncError(failure, StackTrace.current),
    );
  }

  Future<void> refresh() async {
    if (state.asData?.value.isSaving == true) return;
    await _load();
  }

  void setEnabled(NotificationPreference preference, bool enabled) {
    final current = state.asData?.value;
    if (current == null || current.isSaving || !preference.userDisableable) {
      return;
    }
    final updated = [
      for (final item in current.preferences)
        if (item.tier == preference.tier && item.channel == preference.channel)
          item.copyWith(enabled: enabled)
        else
          item,
    ];
    state = AsyncData(
      current.copyWith(
        preferences: List.unmodifiable(updated),
        clearSaveFailure: true,
      ),
    );
  }

  Future<void> save() async {
    final current = state.asData?.value;
    if (current == null || !current.isDirty || current.isSaving) return;

    state = AsyncData(current.copyWith(isSaving: true, clearSaveFailure: true));
    final result = await ref
        .read(updateNotificationPreferencesUseCaseProvider)
        .call(current.preferences);
    state = result.when(
      ok: (_) {
        final saved = List<NotificationPreference>.unmodifiable(
          current.preferences
              .map(
                (preference) =>
                    preference.copyWith(enabled: preference.effectiveEnabled),
              )
              .toList(growable: false),
        );
        return AsyncData(
          NotificationPreferencesState(
            preferences: saved,
            savedPreferences: saved,
          ),
        );
      },
      err: (failure) =>
          AsyncData(current.copyWith(isSaving: false, saveFailure: failure)),
    );
  }
}

final notificationPreferencesControllerProvider =
    NotifierProvider<
      NotificationPreferencesController,
      AsyncValue<NotificationPreferencesState>
    >(NotificationPreferencesController.new);

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
