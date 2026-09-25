import 'payment_phone_info.dart';

/// Paymob's wallet top-up `billing_data` requires name/email/phone, so
/// `POST /v1/wallet/top-up` nests this object (`clinic-reservations`
/// `PaymentCustomerInfoDto`, File 12 Part 50). Appointment Fawry uses the
/// smaller [PaymentPhoneInfo] contract instead.
///
/// Collected from a checkout form rather than read off the session:
/// `identity-auth` exports only a masked-phone projection cross-module and
/// no email at all, so the profile genuinely cannot supply these.
///
/// This remains separate from the appointment Fawry contact model because
/// Paymob's card top-up contract needs billing fields that Fawry does not.
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
