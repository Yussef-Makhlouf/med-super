/// A pharmacy branch that can fulfil the uploaded prescription — the branch,
/// not the pharmacy chain, since only a branch has an address to act on and
/// the same chain can have more than one (see
/// `GET /v1/pharmacy-branches/search`, `clinic-reservations` File 12 Part
/// 37). `rating`/`ratingCount`/live open-closed status were dropped
/// 2026-08-29: the real endpoint has no such columns (no reviews model, no
/// operating-hours model on `PharmacyBranch`), so they can't be backed by
/// real data and were removed from the card rather than shown as fake.
class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.deliveryCapable,
    this.distanceKm,
  });

  final String id;
  final String name;

  /// Street address shown next to the distance on the pharmacy card, e.g.
  /// "شارع التحلية، الرياض".
  final String address;
  final double latitude;
  final double longitude;

  /// `pharmacy_branches.delivery_capable` — real backend data, unlike the
  /// rating/open-status fields dropped 2026-08-29.
  final bool deliveryCapable;

  /// Distance from the patient's current location — null when the device's
  /// location wasn't available (permission denied/disabled), in which case
  /// the card hides the distance row rather than showing a fabricated value.
  final double? distanceKm;
}
