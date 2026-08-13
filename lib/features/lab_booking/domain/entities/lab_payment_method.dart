/// Payment method offered on the review step.
enum LabPaymentMethod {
  onlinePayment,
  payAtService;

  /// Localization key under `lab_booking.review.*`.
  String get labelKey => switch (this) {
    LabPaymentMethod.onlinePayment => 'lab_booking.review.payment_online',
    LabPaymentMethod.payAtService => 'lab_booking.review.payment_at_service',
  };

  /// Localization key for the small grey subtitle under the label.
  String get subtitleKey => switch (this) {
    LabPaymentMethod.onlinePayment => 'lab_booking.review.payment_online_sub',
    LabPaymentMethod.payAtService =>
      'lab_booking.review.payment_at_service_sub',
  };

  String get apiValue => switch (this) {
    LabPaymentMethod.onlinePayment => 'online_payment',
    LabPaymentMethod.payAtService => 'pay_at_service',
  };
}
