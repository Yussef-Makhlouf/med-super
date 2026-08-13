/// Sort order for the pharmacy list (step 2 of the booking flow). Mutually
/// exclusive with the separate "مفتوح الآن" filter toggle, mirroring
/// `LabSortOption`'s split between sort chips and a standalone filter chip.
enum PharmacySortOption {
  topRated,
  nearest;

  String get apiValue => switch (this) {
    PharmacySortOption.topRated => 'top_rated',
    PharmacySortOption.nearest => 'nearest',
  };
}
