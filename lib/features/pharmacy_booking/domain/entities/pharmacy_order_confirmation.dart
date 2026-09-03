/// Result of confirming a pharmacy order — drives the success screen (step
/// 3 result).
///
/// The order is only *submitted* here, not confirmed: the final medication
/// cost is only known once the pharmacist reviews the uploaded prescription
/// image and responds.
class PharmacyOrderConfirmation {
  const PharmacyOrderConfirmation({
    required this.orderNumber,
    required this.pharmacyName,
  });

  final String orderNumber;
  final String pharmacyName;
}
