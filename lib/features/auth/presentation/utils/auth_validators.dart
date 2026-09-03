/// Shared auth form validators for password fields.
///
/// Pure Dart (no Flutter imports). Callers call `.tr()` on the returned
/// translation key (easy_localization), same pattern as the existing
/// FormField validator in login_screen.dart's _PhoneField.
library;

/// Password length bounds shared by validation and input formatters.
const passwordMinLength = 8;
const passwordMaxLength = 64;

/// Validates a password value, returning the first failing translation
/// key in this order, or `null` if all checks pass:
/// 1. empty -> 'auth.password_required'
/// 2. length < 8 -> 'auth.password_too_short'
/// 3. length > 64 -> 'auth.password_too_long'
/// 4. no uppercase letter -> 'auth.password_needs_uppercase'
/// 5. no lowercase letter -> 'auth.password_needs_lowercase'
/// 6. no digit -> 'auth.password_needs_number'
/// 7. no special character (anything outside [A-Za-z0-9]) ->
///    'auth.password_needs_special'
String? validatePassword(String value) {
  if (value.isEmpty) {
    return 'auth.password_required';
  }
  if (value.length < passwordMinLength) {
    return 'auth.password_too_short';
  }
  if (value.length > passwordMaxLength) {
    return 'auth.password_too_long';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'auth.password_needs_uppercase';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'auth.password_needs_lowercase';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'auth.password_needs_number';
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'auth.password_needs_special';
  }
  return null;
}

/// Individual password-requirement checks, exposed separately from
/// [validatePassword] so UI can render a live checklist/chips as the user
/// types instead of only surfacing the first failing rule.
bool passwordHasMinLength(String value) =>
    value.length >= passwordMinLength && value.length <= passwordMaxLength;

bool passwordHasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);

bool passwordHasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);

bool passwordHasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);

bool passwordHasSymbol(String value) =>
    RegExp(r'[^A-Za-z0-9]').hasMatch(value);

/// Coarse strength bucket for the live strength label shown under the
/// password field. Based on how many of the 5 requirement checks pass.
enum PasswordStrength { weak, medium, strong }

PasswordStrength passwordStrength(String value) {
  if (value.isEmpty) return PasswordStrength.weak;
  final score = [
    passwordHasMinLength(value),
    passwordHasUppercase(value),
    passwordHasLowercase(value),
    passwordHasNumber(value),
    passwordHasSymbol(value),
  ].where((met) => met).length;
  if (score >= 5) return PasswordStrength.strong;
  if (score >= 3) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

/// Validates that [confirmation] matches [password].
///
/// Returns 'auth.password_confirm_required' when [confirmation] is empty,
/// 'auth.password_mismatch' when it does not equal [password], or `null`
/// when valid.
String? validatePasswordConfirmation(String password, String confirmation) {
  if (confirmation.isEmpty) {
    return 'auth.password_confirm_required';
  }
  if (confirmation != password) {
    return 'auth.password_mismatch';
  }
  return null;
}
