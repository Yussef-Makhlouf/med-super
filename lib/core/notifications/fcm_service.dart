import 'dart:async';

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
  FcmService(this._messaging);

  final FirebaseMessaging _messaging;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  int _generation = 0;

  Future<bool> init({
    required void Function(RemoteMessage) onMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    final generation = ++_generation;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (generation != _generation || !_canReceive(settings)) return false;

      // Foreground pushes never show a tray notification on their own —
      // the caller is expected to display one via LocalNotificationService.
      await _messageSubscription?.cancel();
      _messageSubscription = FirebaseMessaging.onMessage.listen(onMessage);

      // Tapping an OS tray notification while the app is backgrounded.
      await _tapSubscription?.cancel();
      _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        onMessageOpenedApp,
      );

      // Tapping an OS tray notification that launched the app from
      // terminated state.
      final initialMessage = await _messaging.getInitialMessage();
      if (generation == _generation && initialMessage != null) {
        onMessageOpenedApp(initialMessage);
      }
      return generation == _generation;
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: init skipped — $e');
      return false;
    }
  }

  bool _canReceive(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  Future<bool> get canReceiveNotifications async {
    try {
      return _canReceive(await _messaging.getNotificationSettings());
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    ++_generation;
    await _messageSubscription?.cancel();
    await _tapSubscription?.cancel();
    _messageSubscription = null;
    _tapSubscription = null;
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
      // On Apple platforms FCM cannot issue a usable token before APNs has
      // assigned its token. A later foreground retry handles that case.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          await _messaging.getAPNSToken() == null) {
        return null;
      }
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
