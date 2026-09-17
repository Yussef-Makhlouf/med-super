import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/data/models/doctor_appointment_dto.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';

void main() {
  test('visit status exposes only the next forward action', () {
    expect(DoctorVisitStatus.waiting.next, DoctorVisitStatus.inDoctorRoom);
    expect(DoctorVisitStatus.inDoctorRoom.next, DoctorVisitStatus.left);
    expect(DoctorVisitStatus.left.next, isNull);
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
}
