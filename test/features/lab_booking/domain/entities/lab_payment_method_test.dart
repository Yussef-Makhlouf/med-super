import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';

void main() {
  test('each value has a distinct labelKey under schedule_payment.*', () {
    final keys = LabPaymentMethod.values.map((m) => m.labelKey).toSet();

    expect(keys, hasLength(LabPaymentMethod.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.schedule_payment.payment_'));
    }
  });

  test('apiValue is a stable snake_case wire value per method', () {
    expect(LabPaymentMethod.creditCard.apiValue, 'credit_card');
    expect(LabPaymentMethod.applePay.apiValue, 'apple_pay');
    expect(LabPaymentMethod.cashAtLab.apiValue, 'cash_at_lab');
  });

  test('each value has a distinct apiValue', () {
    final values = LabPaymentMethod.values.map((m) => m.apiValue).toSet();
    expect(values, hasLength(LabPaymentMethod.values.length));
  });
}
