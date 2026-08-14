/// API path segments mirroring SRS §16 endpoint groups.
abstract final class ApiPaths {
  // Auth
  static const otpRequest = '/v1/auth/otp/request';
  static const otpVerify = '/v1/auth/otp/verify';
  static const refresh = '/v1/auth/token/refresh';
  static const me = '/v1/auth/me';
  static const logout = '/v1/auth/logout';

  // Provider directory
  // Real backend route is GET /v1/doctors/search (provider-directory module) —
  // was `/v1/search/doctors` here, which does not exist on the backend and
  // would 404 the instant BASE_URL points at a real server. Fixed per the
  // backend/frontend parity audit (med-super/docs/backend_frontend_parity_matrix.md).
  static const doctors = '/v1/doctors';
  static const clinics = '/v1/clinics';
  static const searchDoctors = '/v1/doctors/search';

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

  // Lab booking
  static const labTests = '/v1/lab-tests';
  static const labPartners = '/v1/lab-partners';
  static const labBookings = '/v1/lab-bookings';

  // Provider registration
  static const providerRegistrationSubmit = '/v1/provider/registration';
  static const providerRegistrationLookups =
      '/v1/provider/registration/lookups';

  // Provider dashboard
  static const providerAppointments = '/v1/provider/appointments';
  static const providerPatients = '/v1/provider/patients';
  static const providerNotifications = '/v1/provider/notifications';
  static const providerMe = '/v1/provider/me';
}
