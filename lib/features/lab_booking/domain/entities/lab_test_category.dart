/// A filter chip category (e.g. "Liver function", "Vitamins").
class LabTestCategory {
  const LabTestCategory({required this.id, required this.labelKey});

  final String id;

  /// Localization key under `lab_booking.categories.*`.
  final String labelKey;
}
