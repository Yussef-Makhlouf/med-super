enum DoctorSort {
  topRated,
  nearest,
  priceLowToHigh;

  // Must match `SORT_VALUES` in clinic-reservations'
  // `doctor-search-query.dto.ts` exactly — the global `ValidationPipe` there
  // runs with `forbidNonWhitelisted: true`, so any other string 400s the
  // whole search request rather than falling back to a default.
  String get apiValue => switch (this) {
    DoctorSort.topRated => 'rating:desc',
    DoctorSort.nearest => 'distance:asc',
    DoctorSort.priceLowToHigh => 'price:asc',
  };

  static DoctorSort fromApi(String? value) => switch (value) {
    'distance:asc' => DoctorSort.nearest,
    'price:asc' => DoctorSort.priceLowToHigh,
    _ => DoctorSort.topRated,
  };
}
