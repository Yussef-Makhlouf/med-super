import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/data/models/doctor_appointment_dto.dart';
import 'package:med_super/features/provider_dashboard/domain/doctor_appointment_visit_action_policy.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';

void main() {
  test('visit status exposes only the next forward action', () {
    expect(DoctorVisitStatus.waiting.next, DoctorVisitStatus.inDoctorRoom);
    expect(DoctorVisitStatus.inDoctorRoom.next, DoctorVisitStatus.left);
    expect(DoctorVisitStatus.left.next, isNull);
    expect(DoctorVisitStatus.cancelled.next, isNull);
    expect(DoctorVisitStatus.timeExpired.next, isNull);
  });

  test('maps cancelled and expired visit states from the backend without counting them as waiting', () {
    expect(DoctorVisitStatusX.fromWire('CANCELLED'), DoctorVisitStatus.cancelled);
    expect(DoctorVisitStatusX.fromWire('TIME_EXPIRED'), DoctorVisitStatus.timeExpired);
    final statuses = [
      DoctorVisitStatus.waiting,
      DoctorVisitStatus.cancelled,
      DoctorVisitStatus.timeExpired,
    ];
    expect(statuses.where((status) => status == DoctorVisitStatus.waiting), hasLength(1));
  });

  test('doctor appointment DTO reads visit status and optimistic-lock version', () {
    final dto = DoctorAppointmentDto.fromJson({
      'appointmentId': 'apt-1',
      'status': 'CONFIRMED',
      'visitStatus': 'IN_DOCTOR_ROOM',
      'version': 7,
      'slotId': 'slot-1',
      'startAt': '2026-09-17T09:00:00.000Z',
      'endAt': '2026-09-17T09:30:00.000Z',
      'doctorClinicAffiliationId': 'aff-1',
      'clinicId': 'clinic-1',
      'clinicName': 'Clinic',
      'clinicBranchId': 'branch-1',
      'clinicBranchPhone': '+20200000000',
      'clinicAddressLine1': '12 Tahrir St',
      'clinicCity': 'Cairo',
      'ianaTimezone': 'Africa/Cairo',
      'patientId': 'patient-1',
      'patientName': 'Mona Hassan',
      'patientPhone': '+201000000009',
      'createdAt': '2026-09-17T08:00:00.000Z',
    }).toEntity();

    expect(dto.visitStatus, DoctorVisitStatus.inDoctorRoom);
    expect(dto.version, 7);
    expect(dto.canAdvanceVisit, isTrue);
  });

  test('cancel/reschedule are allowed only while the patient is still waiting', () {
    DoctorAppointment appointment(
      DoctorAppointmentStatus status,
      DoctorVisitStatus visitStatus,
    ) => DoctorAppointment(
      appointmentId: 'apt-1',
      status: status,
      slotId: 'slot-1',
      startAt: DateTime.utc(2026, 9, 17, 9),
      endAt: DateTime.utc(2026, 9, 17, 9, 30),
      doctorClinicAffiliationId: 'aff-1',
      clinicId: 'clinic-1',
      clinicName: 'Clinic',
      clinicBranchId: 'branch-1',
      clinicBranchPhone: '+20200000000',
      clinicAddressLine1: '12 Tahrir St',
      clinicCity: 'Cairo',
      ianaTimezone: 'Africa/Cairo',
      patientId: 'patient-1',
      patientName: 'Mona Hassan',
      patientPhone: '+201000000009',
      createdAt: DateTime.utc(2026, 9, 17, 8),
      visitStatus: visitStatus,
    );

    const confirmed = DoctorAppointmentStatus.confirmed;
    expect(appointment(confirmed, DoctorVisitStatus.waiting).canChangeBooking, isTrue);
    expect(appointment(confirmed, DoctorVisitStatus.inDoctorRoom).canChangeBooking, isFalse);
    expect(appointment(confirmed, DoctorVisitStatus.left).canChangeBooking, isFalse);
    expect(
      appointment(DoctorAppointmentStatus.rescheduled, DoctorVisitStatus.waiting).canChangeBooking,
      isFalse,
    );
  });

  group('visit day window in the branch zone (PM-APPT-03)', () {
    const policy = DoctorAppointmentVisitActionPolicy();
    DoctorAppointment appointment(
      DateTime startAt, {
      DoctorVisitStatus visitStatus = DoctorVisitStatus.waiting,
      DoctorAppointmentStatus status = DoctorAppointmentStatus.confirmed,
      String ianaTimezone = 'Africa/Cairo',
    }) => DoctorAppointment(
      appointmentId: 'apt-1', status: status, slotId: 'slot-current',
      startAt: startAt, endAt: startAt.add(const Duration(minutes: 30)),
      doctorClinicAffiliationId: 'aff-1', clinicId: 'clinic-1',
      clinicName: 'Clinic', clinicBranchId: 'branch-1', clinicBranchPhone: '+20200000000',
      clinicAddressLine1: '12 Tahrir St', clinicCity: 'Cairo', ianaTimezone: ianaTimezone,
      patientId: 'patient-1', patientName: 'Mona Hassan', patientPhone: '+201000000009',
      createdAt: DateTime.utc(2026, 9, 17, 8), visitStatus: visitStatus,
    );
    const available = DoctorAppointmentVisitActionAvailability.available;
    const notToday = DoctorAppointmentVisitActionAvailability.notOnAppointmentDay;

    test('summer (+03): 23:30 start can be admitted at 23:59, not at 00:00', () {
      final start = DateTime.utc(2026, 7, 15, 20, 30); // 23:30 Cairo
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 7, 15, 20, 59)), available);
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 7, 15, 21)), notToday);
    });

    test('winter (+02): the same wall-clock boundary is an hour later in UTC', () {
      final start = DateTime.utc(2026, 1, 15, 21, 30); // 23:30 Cairo
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 1, 15, 21, 59)), available);
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 1, 15, 22)), notToday);
    });

    test('an active visit can still be finished after midnight', () {
      final start = DateTime.utc(2026, 7, 15, 20, 30);
      expect(
        policy.evaluate(appointment(start, visitStatus: DoctorVisitStatus.inDoctorRoom), nowUtc: DateTime.utc(2026, 7, 15, 21, 15)),
        available,
      );
    });

    test('future-day and old past-day appointments cannot be started', () {
      final start = DateTime.utc(2026, 10, 10, 7);
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 10, 9, 7)), notToday);
      expect(policy.evaluate(appointment(start), nowUtc: DateTime.utc(2026, 10, 12, 7)), notToday);
    });

    test('an unknown zone fails closed, like the server', () {
      final start = DateTime.utc(2026, 10, 3, 7);
      expect(policy.evaluate(appointment(start, ianaTimezone: 'Mars/Base'), nowUtc: start), notToday);
    });

    test('system terminal states and NO_SHOW offer no action', () {
      final start = DateTime.utc(2026, 10, 3, 7);
      expect(
        policy.evaluate(appointment(start, visitStatus: DoctorVisitStatus.timeExpired), nowUtc: start),
        DoctorAppointmentVisitActionAvailability.terminal,
      );
      expect(
        policy.evaluate(appointment(start, status: DoctorAppointmentStatus.noShow, visitStatus: DoctorVisitStatus.timeExpired), nowUtc: start),
        DoctorAppointmentVisitActionAvailability.unavailable,
      );
    });
  });

  test('parses system visit states and NO_SHOW instead of folding them into waiting/other', () {
    expect(DoctorVisitStatusX.fromWire('TIME_EXPIRED'), DoctorVisitStatus.timeExpired);
    expect(DoctorVisitStatusX.fromWire('CANCELLED'), DoctorVisitStatus.cancelled);
    expect(DoctorVisitStatus.timeExpired.next, isNull);
    expect(DoctorAppointmentStatusX.fromWire('NO_SHOW'), DoctorAppointmentStatus.noShow);
    expect(DoctorAppointmentStatus.noShow.wireValue, 'NO_SHOW');
  });
}
