import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/get_provider_patients_usecase.dart';

DoctorAppointment _appointment({
  required String id,
  required String patientId,
  required String patientName,
  required String patientPhone,
  required DateTime startAt,
  required DateTime createdAt,
  DoctorAppointmentStatus status = DoctorAppointmentStatus.confirmed,
}) => DoctorAppointment(
  appointmentId: id,
  status: status,
  slotId: 'slot-$id',
  startAt: startAt,
  endAt: startAt.add(const Duration(minutes: 30)),
  doctorClinicAffiliationId: 'aff-1',
  clinicId: 'clinic-1',
  clinicName: 'Nile Clinic',
  clinicBranchId: 'branch-1',
  clinicBranchPhone: '+20200000001',
  clinicAddressLine1: '12 Tahrir St',
  clinicCity: 'Cairo',
  ianaTimezone: 'Africa/Cairo',
  patientId: patientId,
  patientName: patientName,
  patientPhone: patientPhone,
  createdAt: createdAt,
);

class _SinglePageRepo implements ProviderDashboardRepository {
  _SinglePageRepo(this.items);

  final List<DoctorAppointment> items;

  @override
  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) async => Result.ok(DoctorAppointmentPage(items: items));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GetProviderPatientsUseCase.callWithAppointments', () {
    test(
      'groups every appointment by patientId, most recent first, matching the dedup pass',
      () async {
        final now = DateTime.utc(2026, 9, 4, 12);
        final aptOld = _appointment(
          id: 'apt-1',
          patientId: 'pat-1',
          patientName: 'Mona Hassan',
          patientPhone: '+201000000001',
          startAt: now.subtract(const Duration(days: 10)),
          createdAt: now.subtract(const Duration(days: 10)),
        );
        final aptNew = _appointment(
          id: 'apt-2',
          patientId: 'pat-1',
          patientName: 'Mona Hassan',
          patientPhone: '+201000000001',
          startAt: now.add(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 1)),
        );
        final aptOther = _appointment(
          id: 'apt-3',
          patientId: 'pat-2',
          patientName: 'Omar Ali',
          patientPhone: '+201000000002',
          startAt: now.add(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
        );
        final repo = _SinglePageRepo([aptOld, aptNew, aptOther]);

        final result = await GetProviderPatientsUseCase(
          repo,
        ).callWithAppointments(now: now);

        result.when(
          ok: (data) {
            expect(data.patients, hasLength(2));
            final pat1Appointments = data.appointmentsByPatientId['pat-1']!;
            expect(pat1Appointments, hasLength(2));
            // Sorted most-recent-startAt-first.
            expect(pat1Appointments.first.appointmentId, 'apt-2');
            expect(pat1Appointments.last.appointmentId, 'apt-1');

            final pat2Appointments = data.appointmentsByPatientId['pat-2']!;
            expect(pat2Appointments, hasLength(1));
            expect(pat2Appointments.single.appointmentId, 'apt-3');
          },
          err: (e) => fail(e.toString()),
        );
      },
    );

    test('an unknown patientId has no entry in the appointments map', () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final repo = _SinglePageRepo([
        _appointment(
          id: 'apt-1',
          patientId: 'pat-1',
          patientName: 'Mona Hassan',
          patientPhone: '+201000000001',
          startAt: now,
          createdAt: now,
        ),
      ]);

      final result = await GetProviderPatientsUseCase(
        repo,
      ).callWithAppointments(now: now);

      result.when(
        ok: (data) => expect(data.appointmentsByPatientId['pat-999'], isNull),
        err: (e) => fail(e.toString()),
      );
    });
  });
}
