/// Result of `POST /v1/pharmacy-orders/:id/approve` — approve and pay, the
/// same moment (File 10 Part 8.1).
class PharmacyOrderApproveResult {
  const PharmacyOrderApproveResult({
    required this.pharmacyOrderId,
    required this.status,
    required this.paymentIntentId,
    required this.totalAmount,
    required this.currency,
  });

  final String pharmacyOrderId;
  final String status;
  final String paymentIntentId;
  final String totalAmount;
  final String currency;
}
