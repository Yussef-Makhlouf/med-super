import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/presentation/utils/specialty_visuals.dart';

void main() {
  group('specialtyIllustrationFor', () {
    test('matches the live UUID catalog by Arabic display name', () {
      const cases = {
        'أمراض القلب': 'specialty_cardiology.png',
        'طب الأطفال': 'specialty_pediatrics.png',
        'الأمراض الجلدية': 'specialty_dermatology.png',
        'طب الأسنان': 'specialty_dental.png',
        'طب العيون': 'specialty_ophthalmology.png',
      };

      for (final entry in cases.entries) {
        final specialty = Specialty(code: 'catalog-uuid', nameAr: entry.key);

        expect(
          specialtyIllustrationFor(specialty),
          'assets/illustrations/${entry.value}',
          reason: 'Should map ${entry.key} to its local illustration',
        );
      }
    });

    test('keeps keyword-based mock codes supported', () {
      const specialty = Specialty(code: 'CARDIOLOGY', nameAr: 'قلب');

      expect(
        specialtyIllustrationFor(specialty),
        'assets/illustrations/specialty_cardiology.png',
      );
    });

    test(
      'returns null for an unmapped specialty so the icon fallback is used',
      () {
        const specialty = Specialty(
          code: 'catalog-uuid',
          nameAr: 'طب الأعصاب',
        );

        expect(specialtyIllustrationFor(specialty), isNull);
      },
    );
  });
}
