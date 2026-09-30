import 'notification_priority.dart';

/// Routes an incoming notification payload to the correct priority tier and
/// decides whether to show a local notification, in-app banner, or escalate.
/// SAFETY_CRITICAL always shows regardless of quiet hours or mute state.
class NotificationPriorityRouter {
  NotificationPriority classify(Map<String, dynamic> payload) {
    // The backend sends the template tier; accept the older priority key for
    // compatibility with notifications already queued before this change.
    final priorityStr =
        payload['tier'] as String? ?? payload['priority'] as String?;
    return switch (priorityStr) {
      'SAFETY_CRITICAL' => NotificationPriority.safetyCritical,
      'TRANSACTIONAL' => NotificationPriority.transactional,
      'INFORMATIONAL' => NotificationPriority.informational,
      'MARKETING' => NotificationPriority.marketing,
      _ => NotificationPriority.informational,
    };
  }

  /// Returns true if this notification should show immediately regardless
  /// of user quiet-hours or mute preferences.
  bool bypassesQuietHours(NotificationPriority priority) =>
      priority == NotificationPriority.safetyCritical;
}
