import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/router/app_router.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/notifications/notification_priority.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/domain/utils/notification_deep_link.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';

/// Wires FCM delivery to the app: shows a short in-app banner when a push
/// arrives in the foreground, and navigates to the right screen when the user
/// taps a notification — whether that tap happened in-app, from the tray
/// while backgrounded, or from a cold start.
///
/// Call [start] once, after the router/session are ready (see
/// `session_provider.dart`).
class PushNotificationCoordinator with WidgetsBindingObserver {
  PushNotificationCoordinator(this._ref);

  final Ref _ref;
  bool _started = false;
  bool _permitted = false;
  bool _observing = false;
  Future<bool>? _startFuture;

  Future<bool> start() async {
    if (_started && _permitted) return true;
    if (_startFuture != null) return _startFuture!;
    _started = true;
    final task = _startInternal();
    _startFuture = task;
    try {
      return await task;
    } finally {
      if (_startFuture == task) _startFuture = null;
    }
  }

  Future<bool> _startInternal() async {
    await _ref
        .read(localNotificationServiceProvider)
        .init(onTap: _handleLocalNotificationTap);
    if (!_started) return false;

    final permitted = await _ref
        .read(fcmServiceProvider)
        .init(
          onMessage: _handleForegroundMessage,
          onMessageOpenedApp: _handleTap,
        );
    if (!_started) return false;
    _permitted = permitted;

    // Covers a push that arrived while the app was backgrounded/killed: the
    // OS tray notification and its badge count are both correct in that
    // case, but the in-app list/bell badge weren't fetched at that point —
    // refresh them the moment the user actually returns to the app.
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    return permitted;
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _permitted = false;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    // An in-flight start may enter FcmService.init after stop was requested.
    // Wait for it to settle, then remove any listeners it created.
    try {
      await _startFuture;
    } finally {
      await _ref.read(fcmServiceProvider).stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_started && state == AppLifecycleState.resumed) {
      _ref.read(notificationListControllerProvider.notifier).refresh();
      _ref.read(sessionControllerProvider.notifier).retryPushRegistration();
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (!_started ||
        _ref.read(sessionControllerProvider).asData?.value == null) {
      return;
    }
    // The inbox and bell must refresh for every event, including marketing
    // and data-only pushes that deliberately do not show an OS popup.
    _ref.read(notificationListControllerProvider.notifier).refresh();
    final priority = _ref
        .read(notificationPriorityRouterProvider)
        .classify(message.data);

    // MARKETING pushes are shown as an in-app inbox entry only (already
    // handled by the pull-based list refresh), never as a popup.
    if (priority == NotificationPriority.marketing) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    // A foreground OS notification duplicates the UI the person is already
    // looking at. Keep the alert inside the app, WhatsApp-style, while the
    // background/terminated path remains handled by FCM/the OS.
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title.isNotEmpty)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            if (body != null && body.isNotEmpty)
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: SnackBarAction(
          label: 'common.open'.tr(),
          onPressed: () => _navigate(message.data),
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    if (!_started) return;
    final templateCode =
        data['templateCode'] as String? ?? data['template_code'] as String?;
    if (templateCode == null) return;

    final session = _ref.read(sessionControllerProvider).asData?.value;
    if (session == null) return;
    final isProvider = session.user.isProvider;

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

final pushNotificationCoordinatorProvider =
    Provider<PushNotificationCoordinator>((ref) {
      // The generated FCM service provider is auto-dispose. Keep its message
      // subscriptions alive for the lifetime of this app-level coordinator.
      ref.watch(fcmServiceProvider);
      return PushNotificationCoordinator(ref);
    });
