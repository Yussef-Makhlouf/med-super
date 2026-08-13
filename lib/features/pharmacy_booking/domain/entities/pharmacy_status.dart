/// Live operating status of a pharmacy, shown as a status row on its card
/// in the select-pharmacy step.
enum PharmacyOpenState {
  open24h,
  openUntil,
  closedUntilTomorrow;

  /// Localization key under `pharmacy_booking.select_pharmacy.*`. Takes a
  /// `{}` time argument except for [open24h], which has none.
  String get labelKey => switch (this) {
    PharmacyOpenState.open24h =>
      'pharmacy_booking.select_pharmacy.status_open_24h',
    PharmacyOpenState.openUntil =>
      'pharmacy_booking.select_pharmacy.status_open_until',
    PharmacyOpenState.closedUntilTomorrow =>
      'pharmacy_booking.select_pharmacy.status_closed_tomorrow',
  };

  bool get isOpen => this != PharmacyOpenState.closedUntilTomorrow;
}

/// Full live-status value for a pharmacy: [state] drives the label/dot
/// color, [time] fills the `{}` placeholder (closing/opening time), unused
/// for [PharmacyOpenState.open24h].
class PharmacyStatus {
  const PharmacyStatus({required this.state, this.time});

  final PharmacyOpenState state;
  final String? time;
}
