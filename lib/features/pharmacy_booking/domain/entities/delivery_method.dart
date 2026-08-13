/// How the patient wants to receive their medication (upload step, step 1).
enum DeliveryMethod {
  pickup,
  homeDelivery;

  /// Localization key for the option's title, under
  /// `pharmacy_booking.upload.*`.
  String get titleKey => switch (this) {
    DeliveryMethod.pickup => 'pharmacy_booking.upload.pickup_title',
    DeliveryMethod.homeDelivery => 'pharmacy_booking.upload.delivery_title',
  };

  String get apiValue => switch (this) {
    DeliveryMethod.pickup => 'pickup',
    DeliveryMethod.homeDelivery => 'home_delivery',
  };
}
