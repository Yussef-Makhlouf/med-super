import 'package:flutter/foundation.dart';

/// Displays local / in-app notifications on behalf of the priority router.
/// Sprint 0: stub — flutter_local_notifications wired in Sprint 5.
class LocalNotificationService {
  Future<void> init() async {
    if (kDebugMode) debugPrint('LocalNotificationService: stub init');
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kDebugMode) debugPrint('LocalNotification[$id]: $title — $body');
  }
}
