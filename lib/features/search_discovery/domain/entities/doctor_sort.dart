enum DoctorSort {
  topRated,
  nearest,
  priceLowToHigh;

  String get apiValue => switch (this) {
    DoctorSort.topRated => 'top_rated',
    DoctorSort.nearest => 'nearest',
    DoctorSort.priceLowToHigh => 'price_asc',
  };

  static DoctorSort fromApi(String? value) => switch (value) {
    'nearest' => DoctorSort.nearest,
    'price_asc' => DoctorSort.priceLowToHigh,
    _ => DoctorSort.topRated,
  };
}
