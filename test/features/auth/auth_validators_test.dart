import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/auth/presentation/utils/auth_validators.dart';

void main() {
  group('validatePassword', () {
    test('returns required key for empty password', () {
      expect(validatePassword(''), 'auth.password_required');
    });

    test('returns too-short key for password under 8 chars', () {
      expect(validatePassword('Ab1!'), 'auth.password_too_short');
    });

    test('returns uppercase key when missing an uppercase letter', () {
      expect(validatePassword('lowercase1!'), 'auth.password_needs_uppercase');
    });

    test('returns lowercase key when missing a lowercase letter', () {
      expect(validatePassword('UPPERCASE1!'), 'auth.password_needs_lowercase');
    });

    test('returns number key when missing a digit', () {
      expect(validatePassword('NoDigitsHere!'), 'auth.password_needs_number');
    });

    test('returns special-char key when missing a special character', () {
      expect(validatePassword('NoSpecial123'), 'auth.password_needs_special');
    });

    test('returns null for a fully valid strong password', () {
      expect(validatePassword('Str0ng!Pass'), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('returns required key when confirmation is empty', () {
      expect(
        validatePasswordConfirmation('Str0ng!Pass', ''),
        'auth.password_confirm_required',
      );
    });

    test('returns mismatch key when confirmation differs from password', () {
      expect(
        validatePasswordConfirmation('Str0ng!Pass', 'Different1!'),
        'auth.password_mismatch',
      );
    });

    test('returns null when confirmation matches password', () {
      expect(
        validatePasswordConfirmation('Str0ng!Pass', 'Str0ng!Pass'),
        isNull,
      );
    });
  });
}
