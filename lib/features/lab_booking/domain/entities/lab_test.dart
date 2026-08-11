/// A single lab test or bundled package, selectable for booking.
class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.isPackage,
    required this.requiresFasting,
    required this.categoryId,
    this.includesCount,
    this.fastingHours,
    this.resultHours,
  });

  final String id;
  final String name;
  final int price;
  final String currency;
  final bool isPackage;
  final bool requiresFasting;

  /// Matches a [LabTestCategory.id] — drives the category chip filter.
  final String categoryId;

  /// Only set when [isPackage] is true.
  final int? includesCount;

  /// Only set when [requiresFasting] is true.
  final int? fastingHours;

  /// Only set when the result turnaround is known.
  final int? resultHours;
}
