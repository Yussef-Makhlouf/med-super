import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/domain/entities/suggested_lab.dart';

void main() {
  test('LabCatalog aggregates categories, tests and suggested labs', () {
    const category = LabTestCategory(id: 'blood', labelKey: 'k');
    const labTest = LabTest(
      id: 't1',
      name: 'CBC',
      price: 100,
      currency: 'EGP',
      isPackage: false,
      requiresFasting: false,
      categoryId: 'blood',
    );
    const suggested = SuggestedLab(
      id: 'l1',
      name: 'Alpha',
      distanceKm: 1,
      rating: 4,
    );

    const catalog = LabCatalog(
      categories: [category],
      tests: [labTest],
      suggestedLabs: [suggested],
    );

    expect(catalog.categories, [category]);
    expect(catalog.tests, [labTest]);
    expect(catalog.suggestedLabs, [suggested]);
  });

  test('LabCatalog can hold empty lists', () {
    const catalog = LabCatalog(categories: [], tests: [], suggestedLabs: []);

    expect(catalog.categories, isEmpty);
    expect(catalog.tests, isEmpty);
    expect(catalog.suggestedLabs, isEmpty);
  });
}
