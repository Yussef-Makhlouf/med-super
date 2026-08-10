import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM token registration/refresh and foreground/background messages.
/// Sprint 0: stub — real Firebase project wired in a later sprint.
class FcmService {
  const FcmService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> init({
    required void Function(RemoteMessage) onMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    try {
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen(onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: init skipped — $e');
    }
  }

  Future<String?> get token async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }
}
