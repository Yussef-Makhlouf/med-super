import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';
import 'package:med_super/features/notifications/domain/repositories/notification_repository.dart';
import 'package:med_super/features/notifications/domain/usecases/update_notification_preferences_usecase.dart';

class _RecordingRepository implements NotificationRepository {
  List<NotificationPreference>? updated;

  @override
  Future<Result<void>> updatePreferences(
    List<NotificationPreference> preferences,
  ) async {
    updated = preferences;
    return const Result<void>.ok(null);
  }

  @override
  Future<Result<List<NotificationPreference>>> getPreferences() async =>
      const Result.ok([]);

  @override
  Future<Result<NotificationListPage>> list({
    bool unreadOnly = false,
    String? cursor,
    int? limit,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> markRead(String id) => throw UnimplementedError();
}

void main() {
  test('forces safety-critical preferences on in the PUT payload', () async {
    final repository = _RecordingRepository();
    final useCase = UpdateNotificationPreferencesUseCase(repository);

    await useCase([
      const NotificationPreference(
        tier: 'SAFETY_CRITICAL',
        channel: 'PUSH',
        enabled: false,
        userDisableable: false,
      ),
      const NotificationPreference(
        tier: 'MARKETING',
        channel: 'SMS',
        enabled: false,
        userDisableable: true,
      ),
    ]);

    expect(repository.updated, isNotNull);
    expect(repository.updated![0].effectiveEnabled, isTrue);
    expect(repository.updated![1].enabled, isFalse);
  });
}
