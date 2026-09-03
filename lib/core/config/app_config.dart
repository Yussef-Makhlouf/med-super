import 'package:flutter/foundation.dart';
import 'package:med_super/app/flavor.dart';

export 'package:med_super/app/flavor.dart' show currentFlavor;

final class AppConfig {
  AppConfig._();

  static final instance = AppConfig._();

  /// Mock base URL used when no real backend is available.
  static const _mockBaseUrl = 'https://mock.medsuper.local';

  String get baseUrl =>
      const String.fromEnvironment('BASE_URL', defaultValue: _mockBaseUrl);

  String get env =>
      const String.fromEnvironment('ENV', defaultValue: 'dev');

  bool get isProduction => env == 'production';

  bool get isMock => baseUrl == _mockBaseUrl;

  bool get isDebug => kDebugMode;

  String get appDisplayName => currentFlavor.displayName;
}
