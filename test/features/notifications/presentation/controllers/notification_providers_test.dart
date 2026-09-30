import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';
import 'package:med_super/features/notifications/domain/usecases/list_notifications_usecase.dart';
import 'package:med_super/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notification(String id, {bool unread = true}) =>
    AppNotification(
      id: id,
      templateCode: 'APPOINTMENT_UPDATE',
      title: 'Title $id',
      body: 'Body $id',
      createdAt: DateTime.utc(2026, 9, 24),
      isUnread: unread,
    );

void main() {
  late _MockNotificationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockNotificationRepository();
    container = ProviderContainer(
      overrides: [
        listNotificationsUseCaseProvider.overrideWithValue(
          ListNotificationsUseCase(repository),
        ),
        markNotificationReadUseCaseProvider.overrideWithValue(
          MarkNotificationReadUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  NotificationListController controller() =>
      container.read(notificationListControllerProvider.notifier);

  NotificationListState currentState() =>
      container.read(notificationListControllerProvider).requireValue;

  test(
    'retries a failed page and appends overlapping notifications once',
    () async {
      var pageAttempts = 0;
      when(
        () => repository.list(
          unreadOnly: any(named: 'unreadOnly'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final cursor = invocation.namedArguments[#cursor] as String?;
        if (cursor == null) {
          return Result.ok(
            NotificationListPage(
              items: [_notification('one')],
              nextCursor: 'cursor-2',
            ),
          );
        }
        pageAttempts++;
        return pageAttempts == 1
            ? const Result.err(
                Failure.server(statusCode: 503, code: 'UNAVAILABLE'),
              )
            : Result.ok(
                NotificationListPage(
                  items: [_notification('one'), _notification('two')],
                  nextCursor: null,
                ),
              );
      });

      await controller().refresh();
      await controller().loadMore();
      expect(currentState().loadMoreFailed, isTrue);
      expect(currentState().items.map((item) => item.id), ['one']);

      await controller().loadMore();
      expect(currentState().loadMoreFailed, isFalse);
      expect(currentState().items.map((item) => item.id), ['one', 'two']);
      expect(currentState().hasMore, isFalse);
    },
  );

  test('stops when the server repeats the active cursor', () async {
    when(
      () => repository.list(
        unreadOnly: any(named: 'unreadOnly'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      return Result.ok(
        NotificationListPage(
          items: [_notification(cursor == null ? 'one' : 'two')],
          nextCursor: 'cursor-2',
        ),
      );
    });

    await controller().refresh();
    await controller().loadMore();

    expect(currentState().items.map((item) => item.id), ['one', 'two']);
    expect(currentState().hasMore, isFalse);
  });

  test(
    'mark all read only updates notifications accepted by the server',
    () async {
      when(
        () => repository.list(
          unreadOnly: any(named: 'unreadOnly'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => Result.ok(
          NotificationListPage(
            items: [_notification('success'), _notification('failure')],
            nextCursor: null,
          ),
        ),
      );
      when(() => repository.markRead(any())).thenAnswer((invocation) async {
        return invocation.positionalArguments.single == 'success'
            ? const Result<void>.ok(null)
            : const Result<void>.err(
                Failure.server(statusCode: 503, code: 'UNAVAILABLE'),
              );
      });

      await controller().refresh();
      await controller().markAllRead();

      expect(currentState().items.map((item) => item.isUnread), [false, true]);
    },
  );
}
