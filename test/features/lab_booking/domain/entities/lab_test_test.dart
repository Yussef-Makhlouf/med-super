import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';

void main() {
  group('LabTest', () {
    test('stores all required fields', () {
      const test = LabTest(
        id: 't1',
        name: 'CBC',
        price: 150,
        currency: 'EGP',
        isPackage: false,
        requiresFasting: false,
        categoryId: 'blood',
      );

      expect(test.id, 't1');
      expect(test.name, 'CBC');
      expect(test.price, 150);
      expect(test.currency, 'EGP');
      expect(test.isPackage, isFalse);
      expect(test.requiresFasting, isFalse);
      expect(test.categoryId, 'blood');
      expect(test.includesCount, isNull);
      expect(test.fastingHours, isNull);
      expect(test.resultHours, isNull);
    });

    test('optional fields are set when provided (package + fasting)', () {
      const test = LabTest(
        id: 'p1',
        name: 'Full Body Package',
        price: 900,
        currency: 'EGP',
        isPackage: true,
        requiresFasting: true,
        categoryId: 'packages',
        includesCount: 12,
        fastingHours: 8,
        resultHours: 24,
      );

      expect(test.isPackage, isTrue);
      expect(test.includesCount, 12);
      expect(test.requiresFasting, isTrue);
      expect(test.fastingHours, 8);
      expect(test.resultHours, 24);
    });
  });
}
