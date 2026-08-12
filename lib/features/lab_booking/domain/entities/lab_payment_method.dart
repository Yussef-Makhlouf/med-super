/// Payment method offered on the schedule & payment step.
enum LabPaymentMethod {
  creditCard,
  applePay,
  cashAtLab;

  /// Localization key under `lab_booking.schedule_payment.*`.
  String get labelKey => switch (this) {
    LabPaymentMethod.creditCard =>
      'lab_booking.schedule_payment.payment_credit_card',
    LabPaymentMethod.applePay =>
      'lab_booking.schedule_payment.payment_apple_pay',
    LabPaymentMethod.cashAtLab =>
      'lab_booking.schedule_payment.payment_cash',
  };

  String get apiValue => switch (this) {
    LabPaymentMethod.creditCard => 'credit_card',
    LabPaymentMethod.applePay => 'apple_pay',
    LabPaymentMethod.cashAtLab => 'cash_at_lab',
  };
}
