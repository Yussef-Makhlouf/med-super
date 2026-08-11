import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/domain/entities/suggested_lab.dart';

class LabTestDto {
  const LabTestDto({
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
  final String categoryId;
  final int? includesCount;
  final int? fastingHours;
  final int? resultHours;

  factory LabTestDto.fromJson(Map<String, dynamic> json) => LabTestDto(
    id: json['id'] as String,
    name: json['name'] as String,
    price: json['price'] as int,
    currency: json['currency'] as String? ?? 'EGP',
    isPackage: json['is_package'] as bool? ?? false,
    requiresFasting: json['requires_fasting'] as bool? ?? false,
    categoryId: json['category_id'] as String? ?? 'packages',
    includesCount: json['includes_count'] as int?,
    fastingHours: json['fasting_hours'] as int?,
    resultHours: json['result_hours'] as int?,
  );

  LabTest toEntity() => LabTest(
    id: id,
    name: name,
    price: price,
    currency: currency,
    isPackage: isPackage,
    requiresFasting: requiresFasting,
    categoryId: categoryId,
    includesCount: includesCount,
    fastingHours: fastingHours,
    resultHours: resultHours,
  );
}

class SuggestedLabDto {
  const SuggestedLabDto({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double rating;

  factory SuggestedLabDto.fromJson(Map<String, dynamic> json) =>
      SuggestedLabDto(
        id: json['id'] as String,
        name: json['name'] as String,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
      );

  SuggestedLab toEntity() =>
      SuggestedLab(id: id, name: name, distanceKm: distanceKm, rating: rating);
}

class LabCatalogDto {
  const LabCatalogDto({
    required this.categories,
    required this.tests,
    required this.suggestedLabs,
  });

  final List<({String id, String labelKey})> categories;
  final List<LabTestDto> tests;
  final List<SuggestedLabDto> suggestedLabs;

  factory LabCatalogDto.fromJson(Map<String, dynamic> json) => LabCatalogDto(
    categories: (json['categories'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((c) => (id: c['id'] as String, labelKey: c['label_key'] as String))
        .toList(),
    tests: (json['tests'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LabTestDto.fromJson)
        .toList(),
    suggestedLabs: (json['suggested_labs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SuggestedLabDto.fromJson)
        .toList(),
  );

  LabCatalog toEntity() => LabCatalog(
    categories: categories
        .map((c) => LabTestCategory(id: c.id, labelKey: c.labelKey))
        .toList(),
    tests: tests.map((t) => t.toEntity()).toList(),
    suggestedLabs: suggestedLabs.map((s) => s.toEntity()).toList(),
  );
}
