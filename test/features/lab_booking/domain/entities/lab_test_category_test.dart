import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';

void main() {
  test('LabTestCategory stores id and labelKey', () {
    const category = LabTestCategory(
      id: 'vitamins',
      labelKey: 'lab_booking.categories.vitamins',
    );

    expect(category.id, 'vitamins');
    expect(category.labelKey, 'lab_booking.categories.vitamins');
  });
}
