import 'package:flutter/foundation.dart';

final class AppConfig {
  AppConfig._();

  static final instance = AppConfig._();

  /// Mock base URL used when no real backend is available.
  static const _mockBaseUrl = 'https://mock.medsuper.local';

  String get baseUrl =>
      const String.fromEnvironment('BASE_URL', defaultValue: _mockBaseUrl);

  String get env => const String.fromEnvironment('ENV', defaultValue: 'dev');

  bool get isProduction => env == 'production';

  bool get isMock => baseUrl == _mockBaseUrl;

  bool get isDebug => kDebugMode;

  /// Web Push certificate key pair's public key (Firebase Console → Project
  /// Settings → Cloud Messaging → Web Push certificates). Required by
  /// `FirebaseMessaging.getToken()` on web only — mobile ignores it.
  String? get fcmVapidKey {
    const value = String.fromEnvironment('FCM_VAPID_KEY');
    return value.isEmpty ? null : value;
  }
}
