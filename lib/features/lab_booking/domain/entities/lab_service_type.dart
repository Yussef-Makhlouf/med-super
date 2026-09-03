/// How the patient wants the lab request fulfilled (upload step, step 1).
enum LabServiceType {
  branchVisit,
  homeCollection;

  /// Localization key for the option's bold title, under
  /// `lab_booking.upload.*`.
  String get titleKey => switch (this) {
    LabServiceType.branchVisit => 'lab_booking.upload.service_branch_title',
    LabServiceType.homeCollection => 'lab_booking.upload.service_home_title',
  };

  /// Localization key for the option's grey subtitle, under
  /// `lab_booking.upload.*`.
  String get subtitleKey => switch (this) {
    LabServiceType.branchVisit => 'lab_booking.upload.service_branch_subtitle',
    LabServiceType.homeCollection => 'lab_booking.upload.service_home_subtitle',
  };

  String get apiValue => switch (this) {
    LabServiceType.branchVisit => 'branch_visit',
    LabServiceType.homeCollection => 'home_collection',
  };
}
