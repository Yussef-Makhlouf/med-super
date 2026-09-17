/// Result of `POST /v1/appointments/{holdId}/payments` (File 12 Part 50.1).
///
/// The appointment is **not** confirmed by this call — the hold is merely
/// extended to the method's own window (15 min for Fawry) and linked to a
/// `CREATED` payment intent. Confirmation happens when the gateway webhook
/// reports success, so the client's job ends at showing [referenceCode].
///
/// [redirectUrl] is populated for `CARD`/`MOBILE_WALLET` only, neither of
/// which this app initiates today — it's parsed rather than dropped so the
/// contract stays honest if that changes.
class OnlinePaymentInitiation {
  const OnlinePaymentInitiation({
    required this.paymentIntentId,
    required this.method,
    required this.expiresAt,
    this.redirectUrl,
    this.referenceCode,
  });

  final String paymentIntentId;
  final String method;
  final DateTime expiresAt;
  final String? redirectUrl;
  final String? referenceCode;
}
