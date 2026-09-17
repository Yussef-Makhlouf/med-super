import 'package:intl/intl.dart';

/// Locale-aware display formatters. Always pass locale explicitly so
/// formatters stay predictable regardless of device locale.
abstract final class AppFormatters {
  /// "Monday, 8 Aug 2026"
  static String fullDate(DateTime date, {String locale = 'en'}) =>
      DateFormat.yMMMMEEEEd(locale).format(date);

  /// "8 Aug" — short date, no year.
  static String shortDate(DateTime date, {String locale = 'en'}) =>
      DateFormat('d MMM', locale).format(date);

  /// "10:30 AM"
  static String time(DateTime date, {String locale = 'en'}) =>
      DateFormat.jm(locale).format(date);

  /// Formats a 24h "HH:mm" string (e.g. from a time-slot API) as a localized
  /// 12h clock time — "10:30 AM".
  static String time12h(String hhmm, {String locale = 'en'}) {
    final parts = hhmm.split(':');
    final reference = DateTime(
      2000,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts.length > 1 ? parts[1] : '0'),
    );
    return time(reference, locale: locale);
  }

  /// "EGP 450.00" — default currency Egyptian Pound.
  static String currency(
    num amount, {
    String symbol = 'EGP',
    String locale = 'en',
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '$symbol ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats an E.164 phone to a local display format.
  /// "+201012345678" → "0101 234 5678"
  static String phone(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('20')) {
      final local = digits.substring(2);
      return '0${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return e164;
  }

  /// Wraps an LTR-only string (phone numbers, IDs, ...) in Unicode
  /// directional-isolate marks (U+2066/U+2069) so it renders left-to-right
  /// in place even inside an RTL (Arabic) layout — without forcing an entire
  /// widget subtree's `Directionality`, which would also flip any
  /// surrounding Arabic text. Without this, a string like "+20 123 456 7890"
  /// gets bidi-reordered into something like "0987 654 321 02+" when it sits
  /// inside RTL text.
  static String ltrIsolate(String value) => '\u2066$value\u2069';
}
