/// Shared duration constants across the app.
abstract final class AppDurations {
  /// Soft appointment-slot hold TTL (SRS §9).
  static const slotHoldTtl = Duration(minutes: 5);

  /// Dio connection / receive timeout.
  static const httpTimeout = Duration(seconds: 30);

  /// Exponential backoff base delay for RetryInterceptor.
  static const retryBaseDelay = Duration(milliseconds: 500);

  /// Maximum number of retry attempts.
  static const retryMaxAttempts = 3;

  /// Search cache TTL.
  static const searchCacheTtl = Duration(minutes: 10);

  /// Doctor profile cache TTL.
  static const profileCacheTtl = Duration(minutes: 30);
}
