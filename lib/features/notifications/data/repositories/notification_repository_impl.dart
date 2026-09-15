import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDatasource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<NotificationListPage>> list({
    bool unreadOnly = false,
    String? cursor,
    int? limit,
  }) => _guard(() async {
    final page = await _remote.list(
      unreadOnly: unreadOnly,
      cursor: cursor,
      limit: limit,
    );
    return page.toEntity();
  });

  @override
  Future<Result<void>> markRead(String id) =>
      _guard(() => _remote.markRead(id));
}
