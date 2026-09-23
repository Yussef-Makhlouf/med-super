/// How the patient chose to pay for a held slot.
///
/// The three values deliberately span two different backend endpoints
/// (`clinic-reservations` File 12 Part 50.1/50.4):
///
///  - `PAY_AT_CLINIC`/`INTERNAL_WALLET` are **synchronous** — `POST
///    /v1/appointments/{holdId}/confirm` creates the `CONFIRMED`
///    appointment in the same call.
///  - `FAWRY` is **asynchronous** — `POST /v1/appointments/{holdId}/payments`
///    only returns a reference code and extends the hold; the appointment
///    is confirmed later by the gateway webhook, never by the client.
///
/// `CARD` and `MOBILE_WALLET` exist on the backend but are absent here on
/// purpose: both return a Paymob checkout URL that needs an in-app browser,
/// and the app has no WebView dependency (see `STATUS.md`). Fawry needs
/// none — its reference code is paid at an outlet.
enum AppointmentPaymentMethod {
  payAtClinic('PAY_AT_CLINIC'),
  wallet('INTERNAL_WALLET'),
  fawry('FAWRY');

  const AppointmentPaymentMethod(this.wireValue);

  final String wireValue;

  bool get isSynchronous => this != AppointmentPaymentMethod.fawry;

  /// Wallet and Fawry accept an optional `paymentAmount`. Pay-at-clinic
  /// rejects one with `422 PAYMENT_AMOUNT_NOT_SUPPORTED`, so the amount
  /// field stays hidden for that tile.
  bool get supportsPartialPayment =>
      this == AppointmentPaymentMethod.wallet ||
      this == AppointmentPaymentMethod.fawry;
}
