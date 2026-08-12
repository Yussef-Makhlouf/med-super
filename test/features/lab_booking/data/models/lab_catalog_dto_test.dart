import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/data/models/lab_catalog_dto.dart';

void main() {
  group('LabTestDto', () {
    test('fromJson parses all fields', () {
      final dto = LabTestDto.fromJson(const {
        'id': 't1',
        'name': 'CBC',
        'price': 150,
        'currency': 'USD',
        'is_package': true,
        'requires_fasting': true,
        'category_id': 'blood',
        'includes_count': 5,
        'fasting_hours': 8,
        'result_hours': 24,
      });

      expect(dto.id, 't1');
      expect(dto.name, 'CBC');
      expect(dto.price, 150);
      expect(dto.currency, 'USD');
      expect(dto.isPackage, isTrue);
      expect(dto.requiresFasting, isTrue);
      expect(dto.categoryId, 'blood');
      expect(dto.includesCount, 5);
      expect(dto.fastingHours, 8);
      expect(dto.resultHours, 24);
    });

    test('fromJson applies defaults for missing optional fields', () {
      final dto = LabTestDto.fromJson(const {
        'id': 't2',
        'name': 'Vitamin D',
        'price': 200,
      });

      expect(dto.currency, 'EGP');
      expect(dto.isPackage, isFalse);
      expect(dto.requiresFasting, isFalse);
      expect(dto.categoryId, 'packages');
      expect(dto.includesCount, isNull);
      expect(dto.fastingHours, isNull);
      expect(dto.resultHours, isNull);
    });

    test('toEntity maps every field 1:1', () {
      final dto = LabTestDto.fromJson(const {
        'id': 't1',
        'name': 'CBC',
        'price': 150,
        'currency': 'EGP',
        'is_package': false,
        'requires_fasting': false,
        'category_id': 'blood',
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.name, dto.name);
      expect(entity.price, dto.price);
      expect(entity.currency, dto.currency);
      expect(entity.isPackage, dto.isPackage);
      expect(entity.requiresFasting, dto.requiresFasting);
      expect(entity.categoryId, dto.categoryId);
      expect(entity.includesCount, dto.includesCount);
      expect(entity.fastingHours, dto.fastingHours);
      expect(entity.resultHours, dto.resultHours);
    });
  });

  group('SuggestedLabDto', () {
    test('fromJson parses provided numeric fields', () {
      final dto = SuggestedLabDto.fromJson(const {
        'id': 'l1',
        'name': 'Alpha',
        'distance_km': 2.5,
        'rating': 4.8,
      });

      expect(dto.id, 'l1');
      expect(dto.name, 'Alpha');
      expect(dto.distanceKm, 2.5);
      expect(dto.rating, 4.8);
    });

    test('fromJson defaults distance/rating to 0 when missing', () {
      final dto = SuggestedLabDto.fromJson(const {'id': 'l2', 'name': 'Beta'});

      expect(dto.distanceKm, 0);
      expect(dto.rating, 0);
    });

    test('fromJson accepts integer json numbers for double fields', () {
      final dto = SuggestedLabDto.fromJson(const {
        'id': 'l3',
        'name': 'Gamma',
        'distance_km': 3,
        'rating': 5,
      });

      expect(dto.distanceKm, 3.0);
      expect(dto.rating, 5.0);
    });

    test('toEntity maps all fields', () {
      final dto = SuggestedLabDto.fromJson(const {
        'id': 'l1',
        'name': 'Alpha',
        'distance_km': 2.5,
        'rating': 4.8,
      });
      final entity = dto.toEntity();

      expect(entity.id, 'l1');
      expect(entity.name, 'Alpha');
      expect(entity.distanceKm, 2.5);
      expect(entity.rating, 4.8);
    });
  });

  group('LabCatalogDto', () {
    test('fromJson parses categories, tests and suggestedLabs', () {
      final dto = LabCatalogDto.fromJson(const {
        'categories': [
          {'id': 'blood', 'label_key': 'lab_booking.categories.blood'},
        ],
        'tests': [
          {
            'id': 't1',
            'name': 'CBC',
            'price': 100,
            'category_id': 'blood',
          },
        ],
        'suggested_labs': [
          {'id': 'l1', 'name': 'Alpha', 'distance_km': 1.0, 'rating': 4.0},
        ],
      });

      expect(dto.categories, hasLength(1));
      expect(dto.categories.single.id, 'blood');
      expect(dto.categories.single.labelKey, 'lab_booking.categories.blood');
      expect(dto.tests, hasLength(1));
      expect(dto.tests.single.id, 't1');
      expect(dto.suggestedLabs, hasLength(1));
      expect(dto.suggestedLabs.single.id, 'l1');
    });

    test('fromJson defaults missing lists to empty', () {
      final dto = LabCatalogDto.fromJson(const {});

      expect(dto.categories, isEmpty);
      expect(dto.tests, isEmpty);
      expect(dto.suggestedLabs, isEmpty);
    });

    test('fromJson filters out non-map entries in lists', () {
      final dto = LabCatalogDto.fromJson(const {
        'categories': ['not-a-map', 42, null],
        'tests': ['bad'],
        'suggested_labs': [3.14],
      });

      expect(dto.categories, isEmpty);
      expect(dto.tests, isEmpty);
      expect(dto.suggestedLabs, isEmpty);
    });

    test('toEntity maps categories/tests/suggestedLabs to entity lists', () {
      final dto = LabCatalogDto.fromJson(const {
        'categories': [
          {'id': 'blood', 'label_key': 'k'},
        ],
        'tests': [
          {'id': 't1', 'name': 'CBC', 'price': 100, 'category_id': 'blood'},
        ],
        'suggested_labs': [
          {'id': 'l1', 'name': 'Alpha', 'distance_km': 1.0, 'rating': 4.0},
        ],
      });

      final entity = dto.toEntity();

      expect(entity.categories, hasLength(1));
      expect(entity.categories.single.id, 'blood');
      expect(entity.tests, hasLength(1));
      expect(entity.tests.single.name, 'CBC');
      expect(entity.suggestedLabs, hasLength(1));
      expect(entity.suggestedLabs.single.name, 'Alpha');
    });
  });
}
