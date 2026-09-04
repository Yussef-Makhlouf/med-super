import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirm_receipt_result.dart';

class PharmacyOrderConfirmReceiptDto {
  const PharmacyOrderConfirmReceiptDto({
    required this.pharmacyOrderId,
    required this.status,
  });

  factory PharmacyOrderConfirmReceiptDto.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderConfirmReceiptDto(
      pharmacyOrderId: json['pharmacyOrderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String pharmacyOrderId;
  final String status;

  PharmacyOrderConfirmReceiptResult toEntity() =>
      PharmacyOrderConfirmReceiptResult(
        pharmacyOrderId: pharmacyOrderId,
        status: status,
      );
}
