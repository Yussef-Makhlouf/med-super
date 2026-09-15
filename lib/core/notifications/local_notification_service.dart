import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Default Android notification channel for foreground-shown pushes.
/// Must match the `default_notification_channel_id` meta-data in
/// AndroidManifest.xml so background/terminated deliveries use the same
/// channel as foreground ones.
const _defaultChannel = AndroidNotificationChannel(
  'medsuper_default_channel',
  'إشعارات ميدسوبر',
  description: 'تنبيهات المواعيد والروشتات ونتائج التحاليل والمدفوعات.',
  importance: Importance.high,
);

/// Displays a real OS-level notification (Android/iOS) when a push arrives
/// while the app is in the foreground — FCM does not show a tray
/// notification on its own in that state, so this bridges the gap.
class LocalNotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> init({void Function(String? payload)? onTap}) async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          onTap?.call(response.payload);
        },
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_defaultChannel);
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotificationService: init failed — $e');
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannel.id,
            _defaultChannel.name,
            channelDescription: _defaultChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotificationService: show failed — $e');
    }
  }
}
