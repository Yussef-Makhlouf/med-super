import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/router/app_router.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/notifications/notification_priority.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/domain/utils/notification_deep_link.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';

/// Wires FCM delivery to the app: shows a real OS notification when a push
/// arrives in the foreground (FCM alone never surfaces a tray notification
/// while the app is open), and navigates to the right screen when the user
/// taps a notification — whether that tap happened in-app, from the tray
/// while backgrounded, or from a cold start.
///
/// Call [start] once, after the router/session are ready (see
/// `session_provider.dart`).
class PushNotificationCoordinator with WidgetsBindingObserver {
  PushNotificationCoordinator(this._ref);

  final Ref _ref;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _ref
        .read(localNotificationServiceProvider)
        .init(onTap: _handleLocalNotificationTap);

    await _ref
        .read(fcmServiceProvider)
        .init(onMessage: _handleForegroundMessage, onMessageOpenedApp: _handleTap);

    // Covers a push that arrived while the app was backgrounded/killed: the
    // OS tray notification and its badge count are both correct in that
    // case, but the in-app list/bell badge weren't fetched at that point —
    // refresh them the moment the user actually returns to the app.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ref.read(notificationListControllerProvider.notifier).refresh();
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final priority = _ref
        .read(notificationPriorityRouterProvider)
        .classify(message.data);

    // MARKETING pushes are shown as an in-app inbox entry only (already
    // handled by the pull-based list refresh), never as an OS tray popup.
    if (priority == NotificationPriority.marketing) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    // flutter_local_notifications requires a non-negative 32-bit id;
    // messageId is unique per push, hashCode alone can be negative.
    final id = (message.messageId ?? message.data.toString()).hashCode & 0x7fffffff;

    _ref
        .read(localNotificationServiceProvider)
        .show(
          id: id,
          title: title ?? '',
          body: body ?? '',
          payload: jsonEncode(message.data),
        );

    // Nothing else invalidates the inbox list when a push lands — without
    // this, the bell badge stays stale (showing the count from whenever the
    // list was last fetched) even though a new notification just arrived
    // and a tray notification is visible.
    _ref.read(notificationListControllerProvider.notifier).refresh();
  }

  void _handleTap(RemoteMessage message) => _navigate(message.data);

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigate(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationCoordinator: bad payload — $e');
      }
    }
  }

  void _navigate(Map<String, dynamic> data) {
    final templateCode = data['templateCode'] as String? ?? data['template_code'] as String?;
    if (templateCode == null) return;

    final session = _ref.read(sessionControllerProvider).asData?.value;
    final isProvider = session?.user.isProvider ?? false;

    final route = notificationDeepLink(
      templateCode: templateCode,
      data: data,
      isProvider: isProvider,
    );
    if (route == null) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.go(route);
  }
}

final pushNotificationCoordinatorProvider = Provider<PushNotificationCoordinator>(
  (ref) => PushNotificationCoordinator(ref),
);
