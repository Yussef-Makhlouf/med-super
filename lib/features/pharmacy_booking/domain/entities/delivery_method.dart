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

  /// `POST /v1/pharmacy-orders`'s `fulfillmentType` enum values.
  String get apiValue => switch (this) {
    DeliveryMethod.pickup => 'PICKUP',
    DeliveryMethod.homeDelivery => 'DELIVERY',
  };

  /// Inverse of [apiValue] — for rendering an already-placed order's
  /// `fulfillmentType` (`GET /v1/pharmacy-orders/:id`) back through the same
  /// [titleKey] the upload step uses, instead of showing the raw API string.
  static DeliveryMethod fromApiValue(String value) => switch (value) {
    'DELIVERY' => DeliveryMethod.homeDelivery,
    _ => DeliveryMethod.pickup,
  };
}
