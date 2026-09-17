/// A lab branch that can fulfil the uploaded lab request — the branch, not
/// the laboratory chain, since only a branch has an address to act on and
/// the same chain can have more than one (`GET /v1/lab-branches/search`,
/// `clinic-reservations` `SearchLabBranchesUseCase`, added 2026-09-05 to
/// un-block this feature — there was previously no way for a patient to
/// discover a branch at all).
///
/// `rating`/`ratingCount`/`startingPrice`/live open-closed status are not
/// fields here: no ratings table, no lab price catalog, and no
/// operating-hours model exist on the real backend, so they can't be backed
/// by real data — same reasoning `Pharmacy` (`pharmacy_booking`) already
/// applied 2026-08-29 when it dropped the same class of fabricated fields.
class LabBranch {
  const LabBranch({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.homeCollectionCapable,
    this.distanceKm,
  });

  final String id;
  final String name;

  /// Street address shown next to the distance on the branch card.
  final String address;
  final double? latitude;
  final double? longitude;

  /// `lab_branches.home_collection_capable` — real backend data, gates
  /// whether home-collection is a legal choice for this branch.
  final bool homeCollectionCapable;

  /// Distance from the patient's current location — null when the device's
  /// location wasn't available (permission denied/disabled), in which case
  /// the card hides the distance row rather than showing a fabricated value.
  final double? distanceKm;
}
