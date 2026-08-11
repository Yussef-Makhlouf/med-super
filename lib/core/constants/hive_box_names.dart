/// Hive box name constants — one source of truth to avoid typo-driven data loss.
abstract final class HiveBoxNames {
  static const settings = 'settings';
  static const doctorSearchCache = 'doctor_search_cache';
  static const appointmentCache = 'appointment_cache';
  static const outbox = 'pending_actions';
  static const labTestsCache = 'lab_tests_cache';
}
