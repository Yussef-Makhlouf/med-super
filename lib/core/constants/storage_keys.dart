/// flutter_secure_storage key constants. Never store PHI here.
abstract final class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const biometricEnabled = 'biometric_enabled';
}

/// Hive settings box keys (non-sensitive UI/local flags).
abstract final class SettingsKeys {
  static const onboardingComplete = 'onboarding_complete';
  static const passwordComplete = 'password_complete';
  static const providerRegistrationSubmitted =
      'provider_registration_submitted';
  /// Set right after a successful OTP verify where the user picked "doctor"
  /// on the login screen's role toggle. Needed because the backend's
  /// `POST /v1/auth/otp/verify` currently ignores the `role` query param
  /// entirely and always creates a PATIENT role_membership (a backend bug,
  /// tracked separately) — so `session.user.isPatient` is `true` for every
  /// brand-new account regardless of which role they picked, and the app
  /// router has no other way to tell "this patient meant to register as a
  /// doctor" from "this is a genuine patient." Cleared once the doctor
  /// registration form is actually submitted (`providerRegistrationSubmitted`
  /// takes over from there) or on logout.
  static const choseDoctorRoleAtSignup = 'chose_doctor_role_at_signup';
}
