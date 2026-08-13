import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_super/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  // Compares with whitespace normalized — some intl locale-data versions
  // use a narrow no-break space (U+202F) before AM/PM instead of a plain
  // space, which would otherwise make an exact string match brittle.
  Matcher matchesTime(String expected) {
    String normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
    return predicate<String>(
      (actual) => normalize(actual) == normalize(expected),
      'matches "$expected" (whitespace-normalized)',
    );
  }

  group('AppFormatters.time12h', () {
    test('formats a morning 24h time as 12h AM', () {
      expect(AppFormatters.time12h('09:30'), matchesTime('9:30 AM'));
    });

    test('formats an afternoon 24h time as 12h PM', () {
      expect(AppFormatters.time12h('16:00'), matchesTime('4:00 PM'));
    });

    test('formats midnight (00:00) as 12:00 AM', () {
      expect(AppFormatters.time12h('00:00'), matchesTime('12:00 AM'));
    });

    test('formats noon (12:00) as 12:00 PM', () {
      expect(AppFormatters.time12h('12:00'), matchesTime('12:00 PM'));
    });

    test('handles an hour-only string without minutes', () {
      expect(AppFormatters.time12h('09'), matchesTime('9:00 AM'));
    });
  });
}
