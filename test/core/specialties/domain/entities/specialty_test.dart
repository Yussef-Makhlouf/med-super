import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';

void main() {
  const pediatrics = Specialty(
    code: 'PEDIATRICS',
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

  test('resolveLabel returns the Arabic name even for an English locale', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'en',
        code: 'PEDIATRICS',
        fallback: 'Pediatrics',
      ),
      'طب الأطفال',
    );
  });

  test('resolveLabel matches the Arabic fallback when code is missing', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'ar',
        fallback: 'طب الأطفال',
      ),
      'طب الأطفال',
    );
  });

  // The catalog no longer carries an English name, but `findIn` also matches
  // a fallback against `code` — so an English fallback that happens to equal
  // the code still resolves to the Arabic name.
  test('resolveLabel matches an English fallback against the code', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'ar',
        fallback: 'Pediatrics',
      ),
      'طب الأطفال',
    );
  });

  test('resolveLabel keeps an English fallback that matches no code', () {
    expect(
      Specialty.resolveLabel(
        catalog: catalog,
        languageCode: 'ar',
        fallback: 'Cardiology',
      ),
      'Cardiology',
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
