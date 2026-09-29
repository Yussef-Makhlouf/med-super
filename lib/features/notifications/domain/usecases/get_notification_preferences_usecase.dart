import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationPreferencesUseCase {
  const GetNotificationPreferencesUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<List<NotificationPreference>>> call() =>
      _repository.getPreferences();
}
