import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';

void main() {
  test('has exactly the two review-step options', () {
    expect(LabPaymentMethod.values, [
      LabPaymentMethod.onlinePayment,
      LabPaymentMethod.payAtService,
    ]);
  });

  test('each value has a distinct labelKey under review.*', () {
    final keys = LabPaymentMethod.values.map((m) => m.labelKey).toSet();

    expect(keys, hasLength(LabPaymentMethod.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.review.payment_'));
    }
  });

  test('each value has a distinct subtitleKey under review.*', () {
    final keys = LabPaymentMethod.values.map((m) => m.subtitleKey).toSet();

    expect(keys, hasLength(LabPaymentMethod.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.review.payment_'));
      expect(key, endsWith('_sub'));
    }
  });

  test('apiValue is a stable snake_case wire value per method', () {
    expect(LabPaymentMethod.onlinePayment.apiValue, 'online_payment');
    expect(LabPaymentMethod.payAtService.apiValue, 'pay_at_service');
  });

  test('each value has a distinct apiValue', () {
    final values = LabPaymentMethod.values.map((m) => m.apiValue).toSet();
    expect(values, hasLength(LabPaymentMethod.values.length));
  });
}
