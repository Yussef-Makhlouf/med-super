import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/appointments/data/models/appointment_summary_dto.dart';

void main() {
  Map<String, dynamic> json({String status = 'CONFIRMED', String? visitStatus}) => {
    'appointmentId': 'apt-1',
    'status': status,
    'slotId': 'slot-1',
    'startAt': '2099-09-17T09:00:00.000Z',
    'endAt': '2099-09-17T09:30:00.000Z',
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

  group('patient start-time cutoff (PM-APPT-01)', () {
    final start = DateTime.utc(2026, 10, 3, 9);
    final appointment = AppointmentSummaryDto.fromJson({
      ...json(visitStatus: 'WAITING'),
      'startAt': start.toIso8601String(),
      'endAt': start.add(const Duration(minutes: 30)).toIso8601String(),
    }).toEntity();

    test('offers cancel/reschedule until 1 ms before start', () {
      expect(appointment.isChangeableAt(start.subtract(const Duration(milliseconds: 1))), isTrue);
    });

    test('hides them at and after the start instant', () {
      expect(appointment.isChangeableAt(start), isFalse);
      expect(appointment.isChangeableAt(start.add(const Duration(minutes: 5))), isFalse);
    });

    test('a past appointment is never cancellable (the reproduced refund hole)', () {
      expect(appointment.isChangeableAt(DateTime.utc(2026, 11, 3)), isFalse);
    });
  });
}
