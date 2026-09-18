/// The caller's own doctor-registration approval state — mirrors the
/// backend's `DoctorStatus` enum (`GET /v1/provider/registration/status`).
enum DoctorRegistrationStatus {
  pending,
  verified,
  suspended;

  static DoctorRegistrationStatus fromApiValue(String value) => switch (value) {
    'VERIFIED' => DoctorRegistrationStatus.verified,
    'SUSPENDED' => DoctorRegistrationStatus.suspended,
    _ => DoctorRegistrationStatus.pending,
  };
}
