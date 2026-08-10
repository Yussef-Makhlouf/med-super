/// API path segments mirroring SRS §16 endpoint groups.
abstract final class ApiPaths {
  // Auth
  static const otpRequest = '/v1/auth/otp/request';
  static const otpVerify = '/v1/auth/otp/verify';
  static const refresh = '/v1/auth/token/refresh';
  static const me = '/v1/auth/me';
  static const logout = '/v1/auth/logout';

  // Provider directory
  static const doctors = '/v1/doctors';
  static const clinics = '/v1/clinics';
  static const search = '/v1/search';
  static const searchDoctors = '/v1/search/doctors';

  // Appointments
  static const appointments = '/v1/appointments';
  static const appointmentHold = '/v1/appointments/hold';

  // Payments
  static const paymentIntents = '/v1/payment-intents';

  // Reviews
  static const reviews = '/v1/reviews';

  // Notifications
  static const notificationPreferences = '/v1/notifications/preferences';
  static const fcmToken = '/v1/notifications/fcm-token';
}
