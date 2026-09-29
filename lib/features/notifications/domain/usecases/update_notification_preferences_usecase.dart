import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';

class UpdateNotificationPreferencesUseCase {
  const UpdateNotificationPreferencesUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<void>> call(List<NotificationPreference> preferences) {
    // Defense in depth: never send an attempt to disable safety-critical
    // alerts even if a future UI accidentally changes a locked row.
    final safePreferences = preferences
        .map(
          (preference) => preference.userDisableable
              ? preference
              : preference.copyWith(enabled: true),
        )
        .toList(growable: false);
    return _repository.updatePreferences(safePreferences);
  }
}
