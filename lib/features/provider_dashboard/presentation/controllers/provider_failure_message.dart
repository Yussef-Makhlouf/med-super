import 'package:easy_localization/easy_localization.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';

/// Doctor-Dashboard wording for a [Failure].
///
/// The shared mapper (`core/error/failure_message.dart`) already resolves
/// `error.code` → Arabic and guarantees nothing English or raw reaches the
/// screen. This layer only exists for the handful of codes where a doctor
/// should read something different from a patient — a doctor cancelling
/// someone else's appointment is told about *the appointment*, not about
/// "your booking" — plus the dashboard's own generic line.
///
/// Anything not listed here falls through to the shared mapper unchanged.
String providerFailureMessage(Failure failure) {
  final override = _doctorOverride(failure);
  if (override != null) return override;
  return failureMessage(
    failure,
    screenFallback: 'provider_dashboard.errors.generic',
  );
}

/// Same mapping for an untyped error escaping an `AsyncValue`.
String providerFailureMessageOf(Object error) => error is Failure
    ? providerFailureMessage(error)
    : 'provider_dashboard.errors.generic'.tr();

/// Doctor-specific copy that differs from the patient-facing catalog.
String? _doctorOverride(Failure failure) {
  if (failure is AuthFailure) {
    return 'provider_dashboard.errors.unauthorized'.tr();
  }

  final code = switch (failure) {
    ServerFailure(:final code) => code,
    ConflictFailure(:final code) => code,
    ValidationFailure(:final code) => code,
    _ => null,
  };

  return switch (code) {
    'APPOINTMENT_NOT_CANCELLABLE' =>
      'provider_dashboard.cancel.not_cancellable'.tr(),
    'APPOINTMENT_NOT_RESCHEDULABLE' =>
      'provider_dashboard.reschedule.not_reschedulable'.tr(),
    'APPOINTMENT_VISIT_IN_PROGRESS' =>
      'provider_dashboard.errors.appointment_visit_in_progress'.tr(),
    'VISIT_STATUS_TOO_EARLY' =>
      'provider_dashboard.visit_status.too_early'.tr(),
    'VISIT_STATUS_OUTSIDE_APPOINTMENT_WINDOW' =>
      'provider_dashboard.visit_status.outside_window'.tr(),
    'INVALID_SCHEDULE_WINDOW' =>
      'provider_dashboard.schedule.invalid_window'.tr(),
    'OPTIMISTIC_LOCK_CONFLICT' || 'APPOINTMENT_STATE_CHANGED' =>
      'provider_dashboard.errors.conflict'.tr(),
    'SLOT_ALREADY_BOOKED' => 'errors.slot_taken'.tr(),
    'ROLE_NOT_PERMITTED' || 'FORBIDDEN' =>
      'provider_dashboard.errors.forbidden'.tr(),
    // The backend deliberately answers 404 rather than 403 for someone
    // else's record, so "not found" and "not yours" are one message here.
    'RESOURCE_NOT_FOUND' || 'RESOURCE_NOT_OWNED' =>
      'provider_dashboard.errors.not_found'.tr(),
    _ => null,
  };
}
