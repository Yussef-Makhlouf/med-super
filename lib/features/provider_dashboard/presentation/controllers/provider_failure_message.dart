import 'package:easy_localization/easy_localization.dart';
import 'package:med_super/core/error/failure.dart';

/// Turns a [Failure] into a localized message for the Doctor Dashboard.
///
/// The backend's error envelope is uniform (`{code, message, ...}`), so the
/// distinctions that actually matter to a doctor are the status classes:
///
///  * **401** — session gone. `mapDioToFailure` collapses this to
///    `AuthFailure` before we ever see a code.
///  * **403** — authenticated, but not a DOCTOR context.
///  * **404** — the resource is not theirs, or no longer exists. The backend
///    deliberately answers 404 rather than 403 for someone else's record, so
///    "not found" and "not yours" are the same message on purpose.
///  * **409** — an optimistic-lock or state race. Reload, don't retry blindly.
///  * **422** — a business rule said no (e.g. cancelling a non-confirmed
///    appointment). The server's own message is the useful one here.
///
/// Known business codes get a specific string; everything else falls back to
/// the server message, and only then to a generic line — never a raw
/// exception or stack trace.
String providerFailureMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure() => 'errors.network'.tr(),
    AuthFailure() => 'provider_dashboard.errors.unauthorized'.tr(),
    ConflictFailure(:final reason) =>
      reason.isEmpty ? 'provider_dashboard.errors.conflict'.tr() : reason,
    ValidationFailure(:final fieldErrors) =>
      fieldErrors.values.firstOrNull ??
          'provider_dashboard.errors.validation'.tr(),
    ServerFailure(:final statusCode, :final code, :final message) =>
      _serverMessage(statusCode, code, message),
    CacheFailure() => 'errors.cache_load_failed'.tr(),
    UnknownFailure() => 'provider_dashboard.errors.generic'.tr(),
  };
}

String _serverMessage(int statusCode, String code, String? message) {
  final businessMessage = switch (code) {
    'APPOINTMENT_NOT_CANCELLABLE' =>
      'provider_dashboard.cancel.not_cancellable'.tr(),
    'APPOINTMENT_NOT_RESCHEDULABLE' =>
      'provider_dashboard.reschedule.not_reschedulable'.tr(),
    'INVALID_SCHEDULE_WINDOW' =>
      'provider_dashboard.schedule.invalid_window'.tr(),
    'OPTIMISTIC_LOCK_CONFLICT' || 'APPOINTMENT_STATE_CHANGED' =>
      'provider_dashboard.errors.conflict'.tr(),
    'SLOT_ALREADY_BOOKED' => 'errors.slot_taken'.tr(),
    'ROLE_NOT_PERMITTED' || 'FORBIDDEN' =>
      'provider_dashboard.errors.forbidden'.tr(),
    'RESOURCE_NOT_FOUND' => 'provider_dashboard.errors.not_found'.tr(),
    _ => null,
  };
  if (businessMessage != null) return businessMessage;

  return switch (statusCode) {
    401 => 'provider_dashboard.errors.unauthorized'.tr(),
    403 => 'provider_dashboard.errors.forbidden'.tr(),
    404 => 'provider_dashboard.errors.not_found'.tr(),
    409 => 'provider_dashboard.errors.conflict'.tr(),
    400 || 422 =>
      message ?? 'provider_dashboard.errors.validation'.tr(),
    _ => message ?? 'provider_dashboard.errors.generic'.tr(),
  };
}

/// Same mapping for an untyped error escaping an `AsyncValue`. Anything that
/// is not a [Failure] falls back to the generic line rather than leaking a
/// raw exception string into the UI.
String providerFailureMessageOf(Object error) =>
    error is Failure
        ? providerFailureMessage(error)
        : 'provider_dashboard.errors.generic'.tr();
