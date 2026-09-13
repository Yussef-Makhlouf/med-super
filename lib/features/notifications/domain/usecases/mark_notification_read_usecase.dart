import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<void>> call(String id) => _repository.markRead(id);
}
