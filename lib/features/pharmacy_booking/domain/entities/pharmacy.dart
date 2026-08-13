import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_status.dart';

/// A pharmacy that can fulfil the uploaded prescription.
class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final String id;
  final String name;

  /// Street address shown next to the distance on the pharmacy card, e.g.
  /// "شارع التحلية، الرياض".
  final String address;
  final double distanceKm;
  final double rating;
  final int ratingCount;
  final double latitude;
  final double longitude;

  /// Live operating status, shown as a status row on the pharmacy card.
  final PharmacyStatus status;
}
