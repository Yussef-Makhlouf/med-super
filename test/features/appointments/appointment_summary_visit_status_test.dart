import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/appointments/data/models/appointment_summary_dto.dart';

void main() {
  Map<String, dynamic> json({String status = 'CONFIRMED', String? visitStatus}) => {
    'appointmentId': 'apt-1',
    'status': status,
    'slotId': 'slot-1',
    'startAt': '2026-09-17T09:00:00.000Z',
    'endAt': '2026-09-17T09:30:00.000Z',
    'doctorClinicAffiliationId': 'aff-1',
    if (visitStatus != null) 'visitStatus': visitStatus,
  };

  test('a waiting confirmed appointment can be cancelled or rescheduled', () {
    final appointment = AppointmentSummaryDto.fromJson(
      json(visitStatus: 'WAITING'),
    ).toEntity();

    expect(appointment.visitStatus, 'WAITING');
    expect(appointment.isCancellable, isTrue);
  });

  test('defaults to WAITING when an older response omits visitStatus', () {
    final appointment = AppointmentSummaryDto.fromJson(json()).toEntity();

    expect(appointment.visitStatus, 'WAITING');
    expect(appointment.isCancellable, isTrue);
  });

  for (final visitStatus in ['IN_DOCTOR_ROOM', 'LEFT']) {
    test('cannot be cancelled or rescheduled once the visit is $visitStatus', () {
      final appointment = AppointmentSummaryDto.fromJson(
        json(visitStatus: visitStatus),
      ).toEntity();

      expect(appointment.isCancellable, isFalse);
    });
  }
}
