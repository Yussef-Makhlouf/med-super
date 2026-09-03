import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_approve_result.dart';

class PharmacyOrderApproveDto {
  const PharmacyOrderApproveDto({
    required this.pharmacyOrderId,
    required this.status,
    required this.paymentIntentId,
    required this.totalAmount,
    required this.currency,
  });

  factory PharmacyOrderApproveDto.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderApproveDto(
      pharmacyOrderId: json['pharmacyOrderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      paymentIntentId: json['paymentIntentId'] as String? ?? '',
      totalAmount: json['totalAmount'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
    );
  }

  final String pharmacyOrderId;
  final String status;
  final String paymentIntentId;
  final String totalAmount;
  final String currency;

  PharmacyOrderApproveResult toEntity() => PharmacyOrderApproveResult(
    pharmacyOrderId: pharmacyOrderId,
    status: status,
    paymentIntentId: paymentIntentId,
    totalAmount: totalAmount,
    currency: currency,
  );
}
