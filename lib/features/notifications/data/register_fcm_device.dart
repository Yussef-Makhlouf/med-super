import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';

String? _currentPlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return null;
}

Future<void> _postToken(Ref ref, String token, String platform) {
  return ref
      .read(authRemoteDatasourceProvider)
      .registerDevice(fcmToken: token, platform: platform);
}

/// Best-effort registration of the device FCM token with
/// `POST /v1/auth/devices` so push notifications can be delivered.
Future<bool> registerFcmDeviceIfAvailable(
  Ref ref, {
  String? refreshedToken,
}) async {
  final platform = _currentPlatform();
  if (platform == null) return false;

  try {
    final fcm = ref.read(fcmServiceProvider);
    if (!await fcm.canReceiveNotifications) return false;
    final token = refreshedToken ?? await fcm.token;
    if (token == null || token.isEmpty) return false;

    await _postToken(ref, token, platform);
    return true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('registerFcmDeviceIfAvailable skipped: $e');
    }
    return false;
  }
}

/// Keeps the backend in step with FCM token rotation.
///
/// FCM can rotate a device's token at any time (app reinstall, restore to a
/// new device, or on its own schedule). Registering only at login leaves the
/// backend holding a token that no longer resolves, so every push to this
/// device silently stops arriving until the user happens to log in again.
///
/// Returns the subscription so the caller can cancel it on logout.
StreamSubscription<String>? listenForFcmTokenRefresh(
  Ref ref,
  void Function(String token) onRefresh,
) {
  final platform = _currentPlatform();
  if (platform == null) return null;

  return ref.read(fcmServiceProvider).onTokenRefresh.listen((token) {
    if (token.isNotEmpty) onRefresh(token);
  });
}
