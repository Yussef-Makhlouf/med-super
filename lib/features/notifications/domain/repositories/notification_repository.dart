import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';

abstract class NotificationRepository {
  Future<Result<NotificationListPage>> list({
    bool unreadOnly = false,
    String? cursor,
    int? limit,
  });

  Future<Result<void>> markRead(String id);

  Future<Result<List<NotificationPreference>>> getPreferences();

  Future<Result<void>> updatePreferences(
    List<NotificationPreference> preferences,
  );
}
