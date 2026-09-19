import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';

void main() {
  const pediatrics = Specialty(
    code: 'PEDIATRICS',
    nameEn: 'Pediatrics',
    nameAr: 'طب الأطفال',
  );
  const catalog = [pediatrics];

  test('resolveLabel uses nameAr when the locale is Arabic', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'ar',
        code: 'PEDIATRICS',
        fallback: 'Pediatrics',
      ),
      'طب الأطفال',
    );
  });

  test('resolveLabel uses nameEn when the locale is English', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'en',
        code: 'PEDIATRICS',
        fallback: 'Pediatrics',
      ),
      'Pediatrics',
    );
  });

  test('resolveLabel matches the English fallback when code is missing', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'ar',
        fallback: 'Pediatrics',
      ),
      'طب الأطفال',
    );
  });

  test('resolveLabel keeps the fallback when the catalog has no match', () {
    expect(
      Specialty.resolveLabel(
        catalog: const [],
        languageCode: 'ar',
        code: 'PEDIATRICS',
        fallback: 'Pediatrics',
      ),
      'Pediatrics',
    );
  });
}
