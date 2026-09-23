import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/appointments/data/models/appointment_hold_dto.dart';
import 'package:med_super/features/appointments/data/models/online_payment_initiation_dto.dart';

void main() {
  group('AppointmentHoldDto', () {
    test('parses the server fee and payment minimum', () {
      final hold = AppointmentHoldDto.fromJson({
        'holdId': 'hold-1',
        'slotId': 'slot-1',
        'expiresAt': '2026-09-21T10:05:00.000Z',
        'status': 'HELD',
        'fullAmount': '500.00',
        'currency': 'EGP',
        'minPaymentAmount': '50.00',
      }).toEntity();

      expect(hold.fullAmount, 500);
      expect(hold.currency, 'EGP');
      expect(hold.minPaymentAmount, 50);
    });

    test('leaves the minimum null when the policy is not configured', () {
      final hold = AppointmentHoldDto.fromJson({
        'holdId': 'hold-1',
        'slotId': 'slot-1',
        'expiresAt': '2026-09-21T10:05:00.000Z',
        'fullAmount': '500.00',
        'minPaymentAmount': null,
      }).toEntity();

      expect(hold.minPaymentAmount, isNull);
    });

    test('still parses a reschedule hold, which has no payment fields', () {
      final hold = AppointmentHoldDto.fromJson({
        'holdId': 'hold-1',
        'slotId': 'slot-1',
        'expiresAt': '2026-09-21T10:05:00.000Z',
        'previousAppointmentId': 'appt-0',
      }).toEntity();

      expect(hold.previousAppointmentId, 'appt-0');
      expect(hold.fullAmount, isNull);
      expect(hold.minPaymentAmount, isNull);
    });
  });

  group('OnlinePaymentInitiationDto', () {
    test('parses the amount the gateway will actually charge', () {
      final initiation = OnlinePaymentInitiationDto.fromJson({
        'paymentIntentId': 'pi-1',
        'method': 'FAWRY',
        'referenceCode': '963455678',
        'expiresAt': '2026-09-21T10:15:00.000Z',
        'amount': '50.00',
        'currency': 'EGP',
      }).toEntity();

      expect(initiation.referenceCode, '963455678');
      expect(initiation.amount, '50.00');
      expect(initiation.currency, 'EGP');
    });
  });
}
