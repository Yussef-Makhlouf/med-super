/// Compact doctor row for search results — pure domain.
class DoctorSummary {
  const DoctorSummary({
    required this.id,
    required this.name,
    required this.specialty,
    required this.locationLabel,
    required this.consultationFee,
    required this.currency,
    this.distanceKm,
    this.photoUrl,
    this.specialtyKey,
  });

  final String id;
  final String name;
  final String specialty;
  final String? specialtyKey;
  final String locationLabel;

  /// Null when the search ran without the device's location (permission
  /// denied/unavailable, or simply not requested yet) — the real backend
  /// only computes this when `lat`/`lng` are sent, never fabricates a
  /// distance otherwise. The card hides its distance text in that case
  /// rather than showing a fabricated "0.0 km".
  final double? distanceKm;
  final int consultationFee;
  final String currency;
  final String? photoUrl;
}
