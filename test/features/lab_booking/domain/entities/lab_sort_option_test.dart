import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

void main() {
  group('LabSortOption.apiValue', () {
    test('nearest maps to "nearest"', () {
      expect(LabSortOption.nearest.apiValue, 'nearest');
    });

    test('priceAsc maps to "price_asc"', () {
      expect(LabSortOption.priceAsc.apiValue, 'price_asc');
    });

    test('ratingDesc maps to "rating_desc"', () {
      expect(LabSortOption.ratingDesc.apiValue, 'rating_desc');
    });

    test('every enum value has a distinct apiValue', () {
      final values = LabSortOption.values.map((v) => v.apiValue).toSet();
      expect(values.length, LabSortOption.values.length);
    });
  });
}
