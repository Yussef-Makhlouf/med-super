import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:med_super/core/config/app_config.dart';

/// Runs in a separate isolate when a push arrives while the app is fully
/// terminated or backgrounded — FCM requires this to be a top-level (or
/// static) function annotated for background execution.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS tray notification is already shown natively by FCM using the
  // `notification` payload + the default channel declared in
  // AndroidManifest.xml — nothing else is needed here. This handler exists
  // so `data`-only messages could be processed later (e.g. local DB sync)
  // without requiring the app to be open.
}

/// Handles FCM token registration/refresh and foreground/background messages.
class FcmService {
  const FcmService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> init({
    required void Function(RemoteMessage) onMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground pushes never show a tray notification on their own —
      // the caller is expected to display one via LocalNotificationService.
      FirebaseMessaging.onMessage.listen(onMessage);

      // Tapping an OS tray notification while the app is backgrounded.
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

      // Tapping an OS tray notification that launched the app from
      // terminated state.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: init skipped — $e');
    }
  }

  /// Fires whenever FCM rotates this device's token. Without re-registering
  /// on rotation the backend keeps only the old token, so every push to this
  /// device silently stops arriving until the next fresh login.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Invalidates this device's token, so pushes for the account that just
  /// signed out stop reaching this device. The next sign-in calls `getToken`
  /// again and registers the new token.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: deleteToken failed — $e');
    }
  }

  Future<String?> get token async {
    try {
      final vapidKey = AppConfig.instance.fcmVapidKey;
      if (kIsWeb && vapidKey == null) {
        if (kDebugMode) {
          debugPrint(
            'FcmService: no FCM_VAPID_KEY set — web push token unavailable. '
            'Pass --dart-define=FCM_VAPID_KEY=<key from Firebase Console '
            '→ Project Settings → Cloud Messaging → Web Push certificates>.',
          );
        }
        return null;
      }
      return await _messaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: getToken failed — $e');
      return null;
    }
  }
}
