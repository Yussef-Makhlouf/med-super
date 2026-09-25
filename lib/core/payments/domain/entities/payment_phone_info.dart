/// Minimum contact information collected for the appointment Fawry flow.
///
/// Names and email are not part of the appointment-payment API payload.
class PaymentPhoneInfo {
  const PaymentPhoneInfo({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}
