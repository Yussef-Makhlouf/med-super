import 'package:med_super/features/appointments/domain/entities/online_payment_initiation.dart';

/// `{ paymentIntentId, method, redirectUrl?, referenceCode?, expiresAt,
/// amount, currency }` —
/// `POST /v1/appointments/{holdId}/payments`
/// (`InitiateOnlineAppointmentPaymentResult`, File 12 Part 50.1).
class OnlinePaymentInitiationDto {
  const OnlinePaymentInitiationDto({
    required this.paymentIntentId,
    required this.method,
    required this.expiresAt,
    this.redirectUrl,
    this.referenceCode,
    this.amount,
    this.currency,
  });

  final String paymentIntentId;
  final String method;
  final DateTime expiresAt;
  final String? redirectUrl;
  final String? referenceCode;
  final String? amount;
  final String? currency;

  factory OnlinePaymentInitiationDto.fromJson(Map<String, dynamic> json) =>
      OnlinePaymentInitiationDto(
        paymentIntentId: json['paymentIntentId'] as String,
        method: json['method'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
        redirectUrl: json['redirectUrl'] as String?,
        // Paymob's Fawry `bill_reference` sometimes comes back as a JSON
        // number rather than a string — `.toString()` handles both instead
        // of throwing a cast error that silently surfaced as a generic
        // "unexpected error" banner on this screen.
        referenceCode: json['referenceCode']?.toString(),
        amount: json['amount'] as String?,
        currency: json['currency'] as String?,
      );

  OnlinePaymentInitiation toEntity() => OnlinePaymentInitiation(
    paymentIntentId: paymentIntentId,
    method: method,
    expiresAt: expiresAt,
    redirectUrl: redirectUrl,
    referenceCode: referenceCode,
    amount: amount,
    currency: currency,
  );
}
