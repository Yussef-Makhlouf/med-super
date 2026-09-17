/// Role memberships returned by Identity (`/v1/auth/me`).
enum UserRole {
  patient,
  doctor,
  clinic,
  pharmacy,
  lab,

  /// Clinic assistant provisioned by a Doctor — maps to backend's
  /// `CLINIC_STAFF` RoleContextType and is offered on password login.
  clinicStaff;

  String get apiValue => switch (this) {
    UserRole.clinicStaff => 'CLINIC_STAFF',
    _ => name.toUpperCase(),
  };

  static UserRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw.toUpperCase()) {
      'PATIENT' => UserRole.patient,
      'DOCTOR' => UserRole.doctor,
      'CLINIC' => UserRole.clinic,
      'PHARMACY' => UserRole.pharmacy,
      'LAB' => UserRole.lab,
      'CLINIC_STAFF' => UserRole.clinicStaff,
      _ => null,
    };
  }

  /// OTP signup only offers patient/doctor; staff roles use password login.
  static UserRole fromLogin(String name) => switch (name.toLowerCase()) {
    'doctor' => UserRole.doctor,
    _ => UserRole.patient,
  };
}
