import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

void main() {
  group('isValidEgyptPhone', () {
    const validPrefixes = ['010', '011', '012', '015'];

    for (final prefix in validPrefixes) {
      // e.g. prefix '010' -> local '01012345678' (11 digits total).
      final local = '$prefix' '12345678'; // 3 + 8 = 11 digits
      final noLeadingZero = local.substring(1); // 10 digits
      final withPlus20 = '+20$noLeadingZero';
      final with20 = '20$noLeadingZero';

      test('accepts local leading-0 form for $prefix', () {
        expect(isValidEgyptPhone(local), isTrue, reason: local);
      });

      test('accepts no-leading-0 form for $prefix', () {
        expect(isValidEgyptPhone(noLeadingZero), isTrue, reason: noLeadingZero);
      });

      test('accepts +20-prefixed form for $prefix', () {
        expect(isValidEgyptPhone(withPlus20), isTrue, reason: withPlus20);
      });

      test('accepts 20-prefixed form for $prefix', () {
        expect(isValidEgyptPhone(with20), isTrue, reason: with20);
      });
    }

    group('invalid operator prefixes', () {
      const invalidPrefixes = ['013', '014', '016', '019'];

      for (final prefix in invalidPrefixes) {
        final local = '$prefix' '12345678'; // 11 digits, bad operator digit
        test('rejects local form for $prefix', () {
          expect(isValidEgyptPhone(local), isFalse, reason: local);
        });
      }
    });

    test('rejects too-short numbers', () {
      expect(isValidEgyptPhone('01012345'), isFalse);
      expect(isValidEgyptPhone('12345'), isFalse);
    });

    test('rejects too-long numbers', () {
      expect(isValidEgyptPhone('010123456789'), isFalse);
      expect(isValidEgyptPhone('2010123456789'), isFalse);
    });

    test('rejects non-digit input', () {
      expect(isValidEgyptPhone(''), isFalse);
      expect(isValidEgyptPhone('abcdefghijk'), isFalse);
      expect(isValidEgyptPhone('phone-number'), isFalse);
    });
  });

  group('normalizeEgyptPhone', () {
    const validPrefixes = ['010', '011', '012', '015'];

    for (final prefix in validPrefixes) {
      final local = '$prefix' '12345678'; // 11 digits
      final noLeadingZero = local.substring(1); // 10 digits
      final withPlus20 = '+20$noLeadingZero';
      final with20 = '20$noLeadingZero';
      final expected = '+20$noLeadingZero';

      test('normalizes local leading-0 form for $prefix', () {
        expect(normalizeEgyptPhone(local), expected);
      });

      test('normalizes no-leading-0 form for $prefix', () {
        expect(normalizeEgyptPhone(noLeadingZero), expected);
      });

      test('normalizes +20-prefixed form for $prefix', () {
        expect(normalizeEgyptPhone(withPlus20), expected);
      });

      test('normalizes 20-prefixed form for $prefix', () {
        expect(normalizeEgyptPhone(with20), expected);
      });
    }
  });
}
