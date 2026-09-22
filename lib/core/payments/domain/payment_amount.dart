/// Wire format for appointment `paymentAmount`.
///
/// `clinic-reservations` rejects a JSON number with `400 VALIDATION_ERROR`
/// — every money value on that API is a **string** with at most 2 decimals
/// (`"50.00"`). The client only proposes an amount; the fee and the
/// configured minimum are server-enforced
/// (`docs/FRONTEND_PAYMENT_CHANGES.md`).
abstract final class PaymentAmount {
  static final _pattern = RegExp(r'^\d+(\.\d{1,2})?$');

  /// `"350"` → `"350.00"`.
  static String fromNum(num amount) => amount.toStringAsFixed(2);

  /// Canonical `"N.NN"` string, or `null` when [raw] is empty, non-numeric,
  /// zero, negative, or has more than 2 fractional digits.
  static String? tryParse(String raw) {
    final trimmed = raw.trim();
    if (!_pattern.hasMatch(trimmed)) return null;
    final value = num.tryParse(trimmed);
    if (value == null || value <= 0) return null;
    return value.toStringAsFixed(2);
  }
}
