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
  const factory Failure.validation(Map<String, String> fieldErrors) =
      ValidationFailure;
  /// Slot just taken, price changed, item OOS — not a generic error.
  const factory Failure.conflict(String reason) = ConflictFailure;
  const factory Failure.cache() = CacheFailure;
  const factory Failure.unknown(Object error, StackTrace stackTrace) =
      UnknownFailure;
}
