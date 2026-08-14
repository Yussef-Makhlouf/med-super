/// Role memberships returned by Identity (`/v1/auth/me`).
enum UserRole {
  patient,
  doctor,
  clinic,
  pharmacy,
  lab;

  String get apiValue => name.toUpperCase();

  static UserRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw.toUpperCase()) {
      'PATIENT' => UserRole.patient,
      'DOCTOR' => UserRole.doctor,
      'CLINIC' => UserRole.clinic,
      'PHARMACY' => UserRole.pharmacy,
      'LAB' => UserRole.lab,
      _ => null,
    };
  }

  /// Login UI only offers patient/doctor; other roles arrive from `/me`.
  static UserRole fromLogin(String name) => switch (name.toLowerCase()) {
    'doctor' => UserRole.doctor,
    _ => UserRole.patient,
  };
}
