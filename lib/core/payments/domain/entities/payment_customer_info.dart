/// Paymob's `billing_data` requires a name/email/phone on every online
/// payment regardless of method, so both `POST /v1/wallet/top-up` and
/// `POST /v1/appointments/{holdId}/payments` nest this object
/// (`clinic-reservations` `PaymentCustomerInfoDto`, File 12 Part 50).
///
/// Collected from a checkout form rather than read off the session:
/// `identity-auth` exports only a masked-phone projection cross-module and
/// no email at all, so the profile genuinely cannot supply these.
///
/// Lives in `core/` because two unrelated features send it — same rationale
/// as `core/specialties/`.
class PaymentCustomerInfo {
  const PaymentCustomerInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
  };
}
