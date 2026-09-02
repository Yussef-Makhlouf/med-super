/// API path segments mirroring SRS §16 endpoint groups.
abstract final class ApiPaths {
  // Auth
  static const otpRequest = '/v1/auth/otp/request';
  static const otpVerify = '/v1/auth/otp/verify';
  static const refresh = '/v1/auth/token/refresh';
  static const me = '/v1/auth/me';
  static const logout = '/v1/auth/logout';
  static const passwordSet = '/v1/auth/password/set';
  static const passwordLogin = '/v1/auth/password/login';
  static const passwordForgot = '/v1/auth/password/forgot';
  // Must be registered as a mock BEFORE `passwordReset` below — this path
  // contains `passwordReset`'s path as a substring, and MockInterceptor
  // matches first-registered-wins substring containment (see the ordering
  // comment on registerFoundationMocks' passwordReset mock).
  static const passwordResetVerifyCode = '/v1/auth/password/reset/verify-code';
  static const passwordReset = '/v1/auth/password/reset';

  // Provider directory
  // Real backend route is GET /v1/doctors/search (provider-directory module) —
  // was `/v1/search/doctors` here, which does not exist on the backend and
  // would 404 the instant BASE_URL points at a real server. Fixed per the
  // backend/frontend parity audit (med-super/docs/backend_frontend_parity_matrix.md).
  static const doctors = '/v1/doctors';
  static const clinics = '/v1/clinics';
  static const clinicBranches = '/v1/clinic-branches';
  static const pharmacies = '/v1/pharmacies';
  static const pharmacyBranches = '/v1/pharmacy-branches';
  static const searchDoctors = '/v1/doctors/search';
  // Static seed data (provider-directory module's SpecialtiesController) —
  // public, no auth, GET only. Returns a raw `Specialty[]` array as the
  // envelope's `data` field (no `{items:[...]}` wrapper).
  static const specialties = '/v1/specialties';

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

  // Prescriptions (Phase 6)
  static const prescriptions = '/v1/prescriptions';

  // Pharmacy Fulfillment (Phase 7)
  static const pharmacyOrders = '/v1/pharmacy-orders';

  // Provider dashboard
  static const providerAppointments = '/v1/provider/appointments';
  static const providerPatients = '/v1/provider/patients';
  static const providerNotifications = '/v1/provider/notifications';
  // Real backend route, replacing the invented `/v1/provider/me` (which
  // never existed anywhere in clinic-reservations) — a DOCTOR-role-only
  // self-profile read/edit (File 12 Part 45).
  static const doctorMe = '/v1/doctors/me';
  // Doctor-only: manage clinic assistants (CLINIC_STAFF accounts).
  // Backend endpoint: POST/GET /v1/provider/assistants,
  // PATCH/DELETE /v1/provider/assistants/:id
  static const providerAssistants = '/v1/provider/assistants';
}
