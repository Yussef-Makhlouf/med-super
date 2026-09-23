import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/payments/domain/payment_amount.dart';

void main() {
  group('PaymentAmount.fromNum', () {
    test('formats with exactly 2 decimals', () {
      expect(PaymentAmount.fromNum(350), '350.00');
      expect(PaymentAmount.fromNum(49.5), '49.50');
    });
  });

  group('PaymentAmount.tryParse', () {
    test('accepts integers and up to 2 decimals, canonicalised', () {
      expect(PaymentAmount.tryParse('50'), '50.00');
      expect(PaymentAmount.tryParse(' 50.5 '), '50.50');
      expect(PaymentAmount.tryParse('299.99'), '299.99');
    });

    test('rejects what the backend rejects', () {
      for (final raw in ['', '0', '0.00', '-50', 'abc', '50.005', '50.', '.5']) {
        expect(PaymentAmount.tryParse(raw), isNull, reason: raw);
      }
    });
  });
}
