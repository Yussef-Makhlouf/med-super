import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/payments/domain/entities/payment_phone_info.dart';

void main() {
  test('appointment Fawry customer payload contains only the phone number', () {
    const info = PaymentPhoneInfo(phone: '+201012345678');

    expect(info.toJson(), {'phone': '+201012345678'});
    expect(info.toJson().keys, isNot(contains('firstName')));
    expect(info.toJson().keys, isNot(contains('lastName')));
    expect(info.toJson().keys, isNot(contains('email')));
  });
}
