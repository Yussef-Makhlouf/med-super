/// Thrown by the data layer; produced by ErrorInterceptor from a Dio failure.
/// Mapped to [Failure] at the repository boundary — never leaks past data layer.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    this.message,
    this.correlationId,
    this.details,
  });

  final int statusCode;

  /// Backend error code string (e.g. "SLOT_TAKEN", "OTP_EXPIRED").
  final String code;
  final String? message;
  final String? correlationId;

  /// Envelope `error.details` — e.g. `{ minAmount: "50.00" }` on
  /// `PAYMENT_AMOUNT_BELOW_MINIMUM`. Opaque to this class; callers that
  /// know a code's shape read the keys they need.
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $message)';
}
