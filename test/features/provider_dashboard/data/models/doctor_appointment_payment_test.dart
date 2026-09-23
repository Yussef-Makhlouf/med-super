import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/data/models/doctor_appointment_dto.dart';

Map<String, dynamic> _json({Object? payment}) => {
  'appointmentId': 'appt-1',
  'status': 'CONFIRMED',
  'slotId': 'slot-1',
  'startAt': '2026-09-10T09:00:00.000Z',
  'endAt': '2026-09-10T09:30:00.000Z',
  'patientName': 'Mona Hassan',
  'createdAt': '2026-09-01T00:00:00.000Z',
  'payment': payment,
};

void main() {
  test('parses a partial payment and the balance left to collect', () {
    final appointment = DoctorAppointmentDto.fromJson(
      _json(
        payment: {
          'method': 'FAWRY',
          'currency': 'EGP',
          'fullAmount': '500.00',
          'paidAmount': '50.00',
          'remainingBalance': '450.00',
        },
      ),
    ).toEntity();

    final payment = appointment.payment!;
    expect(payment.method, 'FAWRY');
    expect(payment.fullAmount, 500);
    expect(payment.paidAmount, 50);
    expect(payment.remainingBalance, 450);
    expect(payment.isFullyPaid, isFalse);
  });

  test('a zero remaining balance reads as fully paid', () {
    final appointment = DoctorAppointmentDto.fromJson(
      _json(
        payment: {
          'method': 'INTERNAL_WALLET',
          'currency': 'EGP',
          'fullAmount': '300.00',
          'paidAmount': '300.00',
          'remainingBalance': '0.00',
        },
      ),
    ).toEntity();

    expect(appointment.payment!.isFullyPaid, isTrue);
  });

  test('null or malformed payment is dropped, not shown as a wrong number', () {
    expect(DoctorAppointmentDto.fromJson(_json()).toEntity().payment, isNull);
    expect(
      DoctorAppointmentDto.fromJson(
        _json(payment: {'method': 'FAWRY', 'paidAmount': 'abc'}),
      ).toEntity().payment,
      isNull,
    );
  });
}
