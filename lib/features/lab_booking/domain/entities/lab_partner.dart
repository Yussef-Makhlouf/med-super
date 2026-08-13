import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

/// An accredited lab that can fulfil the uploaded lab request.
class LabPartner {
  const LabPartner({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.startingPrice,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final String id;
  final String name;

  /// Street address shown next to the distance on the partner card, e.g.
  /// "شارع الجمهورية، مفاعية".
  final String address;
  final double distanceKm;
  final double rating;
  final int ratingCount;

  /// Starting price for this partner's services. The actual cost is only
  /// known once the requested tests are reviewed, so this is a floor, not a
  /// quote — surfaced in the UI as "starting from".
  final int startingPrice;
  final double latitude;
  final double longitude;

  /// Live operating status, shown as a status chip on the partner card.
  final LabPartnerStatus status;
}
