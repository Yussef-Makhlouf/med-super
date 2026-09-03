/// Sort order for the lab-partner list (step 2 of the booking flow).
enum LabSortOption {
  nearest,
  priceAsc,
  ratingDesc;

  String get apiValue => switch (this) {
    LabSortOption.nearest => 'nearest',
    LabSortOption.priceAsc => 'price_asc',
    LabSortOption.ratingDesc => 'rating_desc',
  };
}
