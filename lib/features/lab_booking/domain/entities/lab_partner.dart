/// An accredited lab that can fulfil the tests selected in step 1.
class LabPartner {
  const LabPartner({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.totalPrice,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double rating;
  final int ratingCount;
  final int totalPrice;
  final double latitude;
  final double longitude;
}
