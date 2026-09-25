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

  /// Stops store/profile builds from silently shipping the local mock API or
  /// an insecure API origin. Internal release-track builds may use staging.
  void validateForStartup() {
    validateBuildConfiguration(
      isReleaseBuild: kReleaseMode,
      env: env,
      baseUrl: baseUrl,
      mockBaseUrl: _mockBaseUrl,
    );
  }

  @visibleForTesting
  static void validateBuildConfiguration({
    required bool isReleaseBuild,
    required String env,
    required String baseUrl,
    required String mockBaseUrl,
  }) {
    if (!isReleaseBuild) return;

    if (env != 'staging' && env != 'production') {
      throw StateError('Release builds require ENV=staging or ENV=production.');
    }

    final uri = Uri.tryParse(baseUrl);
    if (baseUrl == mockBaseUrl ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      throw StateError('Release builds require a real HTTPS BASE_URL.');
    }
  }

  /// Web Push certificate key pair's public key (Firebase Console → Project
  /// Settings → Cloud Messaging → Web Push certificates). Required by
  /// `FirebaseMessaging.getToken()` on web only — mobile ignores it.
  String? get fcmVapidKey {
    const value = String.fromEnvironment('FCM_VAPID_KEY');
    return value.isEmpty ? null : value;
  }
}
