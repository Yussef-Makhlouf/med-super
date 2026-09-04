import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
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

/// A repo fake that serves appointments across N pages, so the use-case's
/// cursor-walking is actually exercised rather than assumed.
class _PagedRepo implements ProviderDashboardRepository {
  _PagedRepo(this.pages);

  /// cursor (null for first page) -> (items, nextCursor)
  final Map<String?, (List<DoctorAppointment>, String?)> pages;

  final List<String?> requestedCursors = [];
  Failure? failOnCursor2;

  @override
  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) async {
    requestedCursors.add(cursor);
    if (failOnCursor2 != null && cursor == 'cursor-2') {
      return Result.err(failOnCursor2!);
    }
    final (items, next) = pages[cursor] ?? (const <DoctorAppointment>[], null);
    return Result.ok(DoctorAppointmentPage(items: items, nextCursor: next));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GetProviderPatientsUseCase', () {
    test('walks every page until nextCursor is null', () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final repo = _PagedRepo({
        null: (
          [
            _appointment(
              id: 'apt-1',
              patientId: 'pat-1',
              patientName: 'Mona Hassan',
              patientPhone: '+201000000001',
              startAt: now.subtract(const Duration(days: 5)),
              createdAt: now.subtract(const Duration(days: 6)),
            ),
          ],
          'cursor-2',
        ),
        'cursor-2': (
          [
            _appointment(
              id: 'apt-2',
              patientId: 'pat-2',
              patientName: 'Omar Ali',
              patientPhone: '+201000000002',
              startAt: now.add(const Duration(days: 2)),
              createdAt: now.subtract(const Duration(days: 1)),
            ),
          ],
          null,
        ),
      });

      final result = await GetProviderPatientsUseCase(repo).call(now: now);

      expect(repo.requestedCursors, [null, 'cursor-2']);
      result.when(
        ok: (patients) {
          expect(patients.map((p) => p.patientId), containsAll(['pat-1', 'pat-2']));
          expect(patients, hasLength(2));
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('dedupes by patientId, keeping most-recently-created name/phone', () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final older = _appointment(
        id: 'apt-1',
        patientId: 'pat-1',
        patientName: 'Old Name',
        patientPhone: '+201000000001',
        startAt: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 20)),
      );
      final newer = _appointment(
        id: 'apt-2',
        patientId: 'pat-1',
        patientName: 'Current Name',
        patientPhone: '+201000000099',
        startAt: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final repo = _PagedRepo({
        null: ([older, newer], null),
      });

      final result = await GetProviderPatientsUseCase(repo).call(now: now);

      result.when(
        ok: (patients) {
          expect(patients, hasLength(1));
          final patient = patients.single;
          expect(patient.patientName, 'Current Name');
          expect(patient.patientPhone, '+201000000099');
          expect(patient.lastAppointmentAt, older.startAt);
          expect(patient.nextAppointmentAt, newer.startAt);
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('surfaces a failure from any page rather than swallowing it', () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final repo = _PagedRepo({
        null: (
          [
            _appointment(
              id: 'apt-1',
              patientId: 'pat-1',
              patientName: 'Mona Hassan',
              patientPhone: '+201000000001',
              startAt: now,
              createdAt: now,
            ),
          ],
          'cursor-2',
        ),
      })..failOnCursor2 = const Failure.server(statusCode: 500, code: 'SERVER_ERROR');

      final result = await GetProviderPatientsUseCase(repo).call(now: now);

      expect(result.isOk, isFalse);
    });

    test('an empty appointment history yields an empty patient list', () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final repo = _PagedRepo({null: (const [], null)});

      final result = await GetProviderPatientsUseCase(repo).call(now: now);

      result.when(
        ok: (patients) => expect(patients, isEmpty),
        err: (e) => fail(e.toString()),
      );
    });
  });
}
