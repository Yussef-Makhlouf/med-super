/// A nearby accredited lab suggested alongside test selection.
class SuggestedLab {
  const SuggestedLab({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double rating;
}
