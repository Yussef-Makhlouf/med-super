import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';

class ListNotificationsUseCase {
  const ListNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<NotificationListPage>> call({
    bool unreadOnly = false,
    String? cursor,
    int? limit,
  }) {
    return _repository.list(
      unreadOnly: unreadOnly,
      cursor: cursor,
      limit: limit,
    );
  }
}
