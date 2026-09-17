/// Result of `POST /v1/pharmacy-orders/:id/confirm-receipt` — the patient
/// confirming a home-delivery order arrived, `OUT_FOR_DELIVERY -> FULFILLED`.
class PharmacyOrderConfirmReceiptResult {
  const PharmacyOrderConfirmReceiptResult({
    required this.pharmacyOrderId,
    required this.status,
  });

  final String pharmacyOrderId;
  final String status;
}
