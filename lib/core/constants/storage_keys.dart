/// flutter_secure_storage key constants. Never store PHI here.
abstract final class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const biometricEnabled = 'biometric_enabled';
}

/// Hive settings box keys (non-sensitive UI/local flags).
abstract final class SettingsKeys {
  static const onboardingComplete = 'onboarding_complete';
}
