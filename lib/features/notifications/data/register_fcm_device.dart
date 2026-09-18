import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';

/// Best-effort registration of the device FCM token with
/// `POST /v1/auth/devices` so push notifications can be delivered.
Future<void> registerFcmDeviceIfAvailable(Ref ref) async {
  final String? platform;
  if (kIsWeb) {
    platform = 'web';
  } else if (Platform.isAndroid) {
    platform = 'android';
  } else if (Platform.isIOS) {
    platform = 'ios';
  } else {
    platform = null;
  }

  if (platform == null) return;

  try {
    final token = await ref.read(fcmServiceProvider).token;
    if (token == null || token.isEmpty) return;

    await ref.read(authRemoteDatasourceProvider).registerDevice(
      fcmToken: token,
      platform: platform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('registerFcmDeviceIfAvailable skipped: $e');
    }
  }
}
