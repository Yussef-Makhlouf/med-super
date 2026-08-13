/// Live operating status of a lab partner, shown as a status chip on its
/// card in the select-lab step.
enum LabPartnerStatus {
  openNow,
  closedNow,
  busyNow;

  /// Localization key under `lab_booking.select_lab.*`.
  String get labelKey => switch (this) {
    LabPartnerStatus.openNow => 'lab_booking.select_lab.status_open',
    LabPartnerStatus.closedNow => 'lab_booking.select_lab.status_closed',
    LabPartnerStatus.busyNow => 'lab_booking.select_lab.status_busy',
  };

  String get apiValue => switch (this) {
    LabPartnerStatus.openNow => 'open_now',
    LabPartnerStatus.closedNow => 'closed_now',
    LabPartnerStatus.busyNow => 'busy_now',
  };

  /// Parses the wire value, defaulting to [openNow] when missing/unknown so
  /// a partner never renders without a status chip.
  static LabPartnerStatus fromApiValue(String? value) => switch (value) {
    'closed_now' => LabPartnerStatus.closedNow,
    'busy_now' => LabPartnerStatus.busyNow,
    _ => LabPartnerStatus.openNow,
  };
}
