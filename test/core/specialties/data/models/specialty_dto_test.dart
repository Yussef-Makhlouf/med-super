import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/specialties/data/models/specialty_dto.dart';

void main() {
  group('SpecialtyDto.fromJson', () {
    test('parses the backend snake_case shape', () {
      final dto = SpecialtyDto.fromJson(const {
        'code': 'CARDIOLOGY',
        'name_ar': 'أمراض القلب',
        'parent_code': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'version': 1,
      });

      expect(dto.code, 'CARDIOLOGY');
      expect(dto.nameAr, 'أمراض القلب');
      expect(dto.parentCode, isNull);
    });

    test('carries a non-null parent_code through', () {
      final dto = SpecialtyDto.fromJson(const {
        'code': 'PEDIATRIC_CARDIOLOGY',
        'name_ar': 'قلب الأطفال',
        'parent_code': 'CARDIOLOGY',
      });

      expect(dto.parentCode, 'CARDIOLOGY');
    });

    test('falls back to an empty string for a missing name', () {
      final dto = SpecialtyDto.fromJson(const {'code': 'X'});

      expect(dto.code, 'X');
      expect(dto.nameAr, '');
    });

    test('toEntity maps every field across', () {
      final entity = SpecialtyDto.fromJson(const {
        'code': 'DENTAL',
        'name_ar': 'أسنان',
        'parent_code': null,
      }).toEntity();

      expect(entity.code, 'DENTAL');
      expect(entity.nameAr, 'أسنان');
      expect(entity.localizedName('ar'), 'أسنان');
      expect(entity.localizedName('en'), 'أسنان');
    });
  });
}
