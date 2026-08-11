/// A generic (id, label) lookup entry — specialties, cities, etc.
/// Pulled from the mock catalog instead of being hardcoded in a screen.
class LookupItem {
  const LookupItem({required this.id, required this.label});
  final String id;
  final String label;
}
