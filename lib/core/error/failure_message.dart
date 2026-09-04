import 'package:easy_localization/easy_localization.dart';
import 'package:med_super/core/error/failure.dart';

/// The one place a [Failure] becomes a sentence a user reads.
///
/// MedSuper is Arabic-only in its user-facing copy. Before this existed,
/// five screens each had their own `_failureMessage` switch and every one of
/// them ended in `message ?? 'errors.server'.tr()` — i.e. it printed the
/// backend's raw `message` verbatim. That was English text on screen for as
/// long as the backend wrote English, and it silently re-broke whenever a
/// screen was copied to a new feature.
///
/// The rules here, in order:
///
///  1. **Code first.** `errors.codes.<CODE>` in `assets/translations/*.json`
///     is the app's own Arabic copy for a backend `error.code`. It wins,
///     because it is written for this screen's audience (a patient reads
///     "اختر موعدًا آخر"; the pharmacist console says something else for the
///     same code).
///  2. **Then the server sentence** — but only if it is actually Arabic. The
///     backend is Arabic-only now (`error-messages.ar.ts`), so this covers
///     any code added there before it is added here.
///  3. **Then a generic Arabic line.** Never a raw exception, never English,
///     never a bare error code.
///
/// `screenFallback` lets a caller supply its own more specific last resort
/// (e.g. `'appointments.cancel_error'`) instead of the generic one.
String failureMessage(Failure failure, {String? screenFallback}) {
  return switch (failure) {
    NetworkFailure() => 'errors.network'.tr(),
    AuthFailure() => 'errors.session_expired'.tr(),
    CacheFailure() => 'errors.cache_load_failed'.tr(),
    UnknownFailure() => _fallback(screenFallback, 'errors.unexpected'),
    ConflictFailure(:final code, :final reason) => _resolve(
      code,
      reason,
      screenFallback,
      'errors.conflict',
    ),
    ValidationFailure(:final code, :final fieldErrors) => _resolve(
      code,
      fieldErrors.values.firstOrNull,
      screenFallback,
      'errors.validation',
    ),
    ServerFailure(:final statusCode, :final code, :final message) => _resolve(
      code,
      message,
      screenFallback,
      _genericKeyForStatus(statusCode),
    ),
  };
}

/// Same mapping for an untyped error escaping an `AsyncValue`. Anything that
/// is not a [Failure] falls back to the generic Arabic line rather than
/// leaking `Exception: ...` into the UI.
String failureMessageOf(Object error, {String? screenFallback}) =>
    error is Failure
    ? failureMessage(error, screenFallback: screenFallback)
    : _fallback(screenFallback, 'errors.unexpected');

/// True when [text] contains Arabic script — the "is this already user-ready
/// copy?" test applied to anything coming off the wire.
bool isArabic(String text) => _arabicScript.hasMatch(text);

final RegExp _arabicScript = RegExp(
  r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]',
);

String _resolve(
  String? code,
  String? serverMessage,
  String? screenFallback,
  String genericKey,
) {
  if (code != null && code.isNotEmpty) {
    final key = 'errors.codes.$code';
    final translated = key.tr();
    // easy_localization returns the key itself when it is missing.
    if (translated != key) return translated;
  }
  if (serverMessage != null &&
      serverMessage.isNotEmpty &&
      isArabic(serverMessage)) {
    return serverMessage;
  }
  return _fallback(screenFallback, genericKey);
}

String _fallback(String? screenFallback, String genericKey) =>
    (screenFallback ?? genericKey).tr();

String _genericKeyForStatus(int statusCode) => switch (statusCode) {
  401 => 'errors.session_expired',
  403 => 'errors.forbidden',
  404 => 'errors.not_found',
  409 => 'errors.conflict',
  429 => 'errors.rate_limited',
  400 || 422 => 'errors.validation',
  _ => 'errors.server',
};
