/// Mirrors the backend's 4-tier notification model (SRS §13).
/// SAFETY_CRITICAL bypasses quiet hours and mute on the client — a missed
/// critical lab-value alert is a patient-safety incident, not a UX preference.
enum NotificationPriority {
  safetyCritical,
  transactional,
  informational,
  marketing,
}
