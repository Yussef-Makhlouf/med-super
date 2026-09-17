import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// One sealed failure union for the whole app — §6.
/// Pattern-match with Dart 3 switch, not .when()/.map().
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.server({
    required int statusCode,
    required String code,
    String? message,
    String? correlationId,
  }) = ServerFailure;
  const factory Failure.auth() = AuthFailure;
  /// [code] is the backend envelope's `error.code` when the 422 came from a
  /// business rule — it is what `failureMessage()` keys the Arabic copy on.
  const factory Failure.validation(
    Map<String, String> fieldErrors, {
    String? code,
  }) = ValidationFailure;

  /// Slot just taken, price changed, item OOS — not a generic error.
  ///
  /// [code] carries the backend envelope's `error.code` (`SLOT_ALREADY_BOOKED`,
  /// `APPOINTMENT_STATE_CHANGED`, ...). Screens map on the code, never on
  /// [reason]'s wording — matching sentences was how this used to break every
  /// time the backend reworded a message.
  const factory Failure.conflict(String reason, {String? code}) =
      ConflictFailure;
  const factory Failure.cache() = CacheFailure;
  const factory Failure.unknown(Object error, StackTrace stackTrace) =
      UnknownFailure;
}
