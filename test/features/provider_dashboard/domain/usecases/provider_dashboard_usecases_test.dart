import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_account_profile.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/doctor_appointment_usecases.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/doctor_clinic_usecases.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/doctor_schedule_template_usecases.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/update_doctor_account_usecase.dart';

/// Covers the Doctor Dashboard use-cases against the **real** contract
/// (`clinic-reservations` File 12 Part 49).
///
/// Rewritten 2026-09-04: the previous version exercised `ClinicSettings`,
/// `getDoctorSchedule` and `uploadAvatar` — three shapes backed by invented
/// `/v1/provider/*` routes that never existed on the backend. Passing tests
/// against an imaginary API proved nothing, so those went with the routes.
class _FakeRepo implements ProviderDashboardRepository {
  _FakeRepo({this.failWith});

  /// When set, every call returns this failure instead — used to assert the
  /// use-cases surface errors rather than swallowing them.
  final Failure? failWith;

  String? lastBranchId;
  String? lastAffiliationId;
  bool? lastActive;
  String? lastCancelNote;
  String? lastRescheduleSlotId;
  DoctorScheduleTemplatePatch? lastPatch;
  int? lastDeleteVersion;
  ({DateTime? from, DateTime? to, DoctorAppointmentStatus? status, String? branch})?
  lastQuery;

  Result<T> _result<T>(T value) =>
      failWith != null ? Result.err(failWith!) : Result.ok(value);

  static final _clinic = DoctorClinic(
    affiliationId: 'aff-1',
    affiliationStatus: AffiliationStatus.active,
    consultFee: '250.00',
    currency: 'EGP',
    clinicId: 'clinic-1',
    clinicName: 'Nile Clinic',
    clinicStatus: ProviderVerificationStatus.verified,
    clinicBranchId: 'branch-1',
    branchStatus: ProviderVerificationStatus.verified,
    phone: '+20200000001',
    ianaTimezone: 'Africa/Cairo',
    address: const ClinicAddress(
      line1: '12 Tahrir St',
      city: 'Cairo',
      regionCode: 'CAI',
      countryCode: 'EG',
    ),
  );

  static final _template = DoctorScheduleTemplate(
    id: 'tmpl-1',
    doctorClinicAffiliationId: 'aff-1',
    clinicBranchId: 'branch-1',
    clinicId: 'clinic-1',
    clinicName: 'Nile Clinic',
    ianaTimezone: 'Africa/Cairo',
    weekday: 1,
    startTime: '09:00',
    endTime: '17:00',
    slotDurationMinutes: 30,
    bufferMinutes: 0,
    version: 3,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );

  static final _appointment = DoctorAppointment(
    appointmentId: 'apt-1',
    status: DoctorAppointmentStatus.confirmed,
    slotId: 'slot-1',
    startAt: DateTime.utc(2026, 9, 10, 9),
    endAt: DateTime.utc(2026, 9, 10, 9, 30),
    doctorClinicAffiliationId: 'aff-1',
    clinicId: 'clinic-1',
    clinicName: 'Nile Clinic',
    clinicBranchId: 'branch-1',
    clinicBranchPhone: '+20200000001',
    clinicAddressLine1: '12 Tahrir St',
    clinicCity: 'Cairo',
    ianaTimezone: 'Africa/Cairo',
    patientId: 'pat-1',
    patientName: 'Mona Hassan',
    patientPhone: '+201000000009',
    createdAt: DateTime.utc(2026, 9, 1),
  );

  @override
  Future<Result<DoctorAccountProfile>> getDoctorAccount() async =>
      _result(
        const DoctorAccountProfile(
          id: 'doc-001',
          name: 'Amr Adel',
          specialty: 'Cardiology',
          licenseNumber: 'LIC-001',
          phone: '+201000000000',
        ),
      );

  @override
  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  }) async => _result(
    DoctorAccountProfile(
      id: 'doc-001',
      name: 'Amr Adel',
      specialty: 'Cardiology',
      licenseNumber: 'LIC-001',
      phone: '+201000000000',
      bio: bio ?? '',
      degree: degree,
      yearsOfExperience: yearsOfExperience,
    ),
  );

  @override
  Future<Result<List<DoctorClinic>>> getMyClinics() async => _result([_clinic]);

  @override
  Future<Result<DoctorClinic>> updateMyClinicBranch({
    required String branchId,
    String? phone,
    String? ianaTimezone,
    String? addressLine1,
    String? addressCity,
  }) async {
    lastBranchId = branchId;
    return _result(
      _clinic.copyWith(
        phone: phone,
        ianaTimezone: ianaTimezone,
        address: _clinic.address.copyWith(
          line1: addressLine1,
          city: addressCity,
        ),
      ),
    );
  }

  @override
  Future<Result<DoctorClinic>> setMyAffiliationActive({
    required String affiliationId,
    required bool active,
  }) async {
    lastAffiliationId = affiliationId;
    lastActive = active;
    return _result(
      _clinic.copyWith(
        affiliationStatus:
            active ? AffiliationStatus.active : AffiliationStatus.paused,
      ),
    );
  }

  @override
  Future<Result<List<DoctorScheduleTemplate>>> getMyScheduleTemplates({
    String? affiliationId,
  }) async => _result([_template]);

  @override
  Future<Result<DoctorScheduleTemplate>> createMyScheduleTemplate(
    NewDoctorScheduleTemplate template,
  ) async => _result(_template);

  @override
  Future<Result<DoctorScheduleTemplate>> updateMyScheduleTemplate({
    required String templateId,
    required DoctorScheduleTemplatePatch patch,
  }) async {
    lastPatch = patch;
    return _result(_template);
  }

  @override
  Future<Result<void>> deleteMyScheduleTemplate({
    required String templateId,
    int? version,
  }) async {
    lastDeleteVersion = version;
    return _result(null);
  }

  @override
  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) async {
    lastQuery = (from: from, to: to, status: status, branch: clinicBranchId);
    return _result(
      DoctorAppointmentPage(items: [_appointment], nextCursor: 'next-page'),
    );
  }

  @override
  Future<Result<DoctorAppointment>> getMyAppointment(String appointmentId) async =>
      _result(_appointment);

  @override
  Future<Result<CancelAppointmentOutcome>> cancelMyAppointment({
    required String appointmentId,
    String? note,
  }) async {
    lastCancelNote = note;
    return _result(
      const CancelAppointmentOutcome(refundAmount: 250, feeApplied: 0),
    );
  }

  @override
  Future<Result<RescheduleAppointmentOutcome>> rescheduleMyAppointment({
    required String appointmentId,
    required String newSlotId,
  }) async {
    lastRescheduleSlotId = newSlotId;
    return _result(
      RescheduleAppointmentOutcome(
        newAppointmentId: 'apt-2',
        slotId: newSlotId,
        previousAppointmentId: appointmentId,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepo repo;

  setUp(() => repo = _FakeRepo());

  group('profile', () {
    test('updates only bio/degree/yearsOfExperience', () async {
      final result = await UpdateDoctorAccountUseCase(
        repo,
      ).call(bio: 'Bio text', degree: 'MBBS', yearsOfExperience: 15);

      result.when(
        ok: (value) {
          expect(value.bio, 'Bio text');
          expect(value.degree, 'MBBS');
          expect(value.yearsOfExperience, 15);
          // Untouchable by this endpoint, by design.
          expect(value.licenseNumber, 'LIC-001');
          expect(value.specialty, 'Cardiology');
        },
        err: (e) => fail(e.toString()),
      );
    });
  });

  group('clinics', () {
    test('lists the doctor clinics with their real status fields', () async {
      final result = await GetMyClinicsUseCase(repo).call();

      result.when(
        ok: (clinics) {
          expect(clinics, hasLength(1));
          expect(clinics.first.clinicBranchId, 'branch-1');
          expect(clinics.first.isAcceptingBookings, isTrue);
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('sends the branch id it was given and returns the updated row', () async {
      final result = await UpdateMyClinicBranchUseCase(
        repo,
      ).call(branchId: 'branch-1', phone: '+20211111111');

      expect(repo.lastBranchId, 'branch-1');
      result.when(
        ok: (clinic) => expect(clinic.phone, '+20211111111'),
        err: (e) => fail(e.toString()),
      );
    });

    test('pausing an affiliation flips the status, and never deletes', () async {
      final result = await SetMyAffiliationActiveUseCase(
        repo,
      ).call(affiliationId: 'aff-1', active: false);

      expect(repo.lastAffiliationId, 'aff-1');
      expect(repo.lastActive, isFalse);
      result.when(
        ok: (clinic) {
          expect(clinic.affiliationStatus, AffiliationStatus.paused);
          expect(clinic.isAcceptingBookings, isFalse);
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('surfaces a 403 rather than swallowing it', () async {
      final failing = _FakeRepo(
        failWith: const Failure.server(
          statusCode: 403,
          code: 'ROLE_NOT_PERMITTED',
        ),
      );

      final result = await GetMyClinicsUseCase(failing).call();

      expect(result.isOk, isFalse);
    });
  });

  group('schedule templates', () {
    test('round-trips the optimistic-lock version on update', () async {
      await UpdateMyScheduleTemplateUseCase(repo).call(
        templateId: 'tmpl-1',
        patch: const DoctorScheduleTemplatePatch(endTime: '15:00', version: 3),
      );

      expect(repo.lastPatch?.version, 3);
      expect(repo.lastPatch?.endTime, '15:00');
    });

    test('passes the version through on delete too', () async {
      await DeleteMyScheduleTemplateUseCase(
        repo,
      ).call(templateId: 'tmpl-1', version: 3);

      expect(repo.lastDeleteVersion, 3);
    });

    test('exposes the branch timezone the times are expressed in', () async {
      final result = await GetMyScheduleTemplatesUseCase(repo).call();

      result.when(
        ok: (templates) {
          expect(templates.first.ianaTimezone, 'Africa/Cairo');
          expect(templates.first.weekday, 1);
          expect(templates.first.version, 3);
        },
        err: (e) => fail(e.toString()),
      );
    });
  });

  group('appointments', () {
    test('forwards every filter and returns the paging cursor', () async {
      final from = DateTime.utc(2026, 9, 10);
      final to = DateTime.utc(2026, 9, 11);

      final result = await GetDoctorAppointmentsUseCase(repo).call(
        from: from,
        to: to,
        status: DoctorAppointmentStatus.confirmed,
        clinicBranchId: 'branch-1',
      );

      expect(repo.lastQuery?.from, from);
      expect(repo.lastQuery?.to, to);
      expect(repo.lastQuery?.status, DoctorAppointmentStatus.confirmed);
      expect(repo.lastQuery?.branch, 'branch-1');
      result.when(
        ok: (page) {
          expect(page.items.single.patientName, 'Mona Hassan');
          expect(page.hasMore, isTrue);
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('cancel forwards the note and reports a full refund with no fee', () async {
      final result = await CancelDoctorAppointmentUseCase(
        repo,
      ).call(appointmentId: 'apt-1', note: 'Doctor unavailable');

      expect(repo.lastCancelNote, 'Doctor unavailable');
      result.when(
        ok: (outcome) {
          expect(outcome.refundAmount, 250);
          expect(outcome.feeApplied, 0);
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('reschedule returns the new appointment id and links the old one', () async {
      final result = await RescheduleDoctorAppointmentUseCase(
        repo,
      ).call(appointmentId: 'apt-1', newSlotId: 'slot-2');

      expect(repo.lastRescheduleSlotId, 'slot-2');
      result.when(
        ok: (outcome) {
          expect(outcome.newAppointmentId, 'apt-2');
          expect(outcome.previousAppointmentId, 'apt-1');
        },
        err: (e) => fail(e.toString()),
      );
    });

    test('a 409 conflict is surfaced, not swallowed', () async {
      final failing = _FakeRepo(
        failWith: const Failure.conflict('APPOINTMENT_STATE_CHANGED'),
      );

      final result = await CancelDoctorAppointmentUseCase(
        failing,
      ).call(appointmentId: 'apt-1');

      expect(result.isOk, isFalse);
    });
  });

  group('status mapping', () {
    test('maps every real wire status, and unknown values to `other`', () {
      expect(
        DoctorAppointmentStatusX.fromWire('CONFIRMED'),
        DoctorAppointmentStatus.confirmed,
      );
      expect(
        DoctorAppointmentStatusX.fromWire('CANCELLED'),
        DoctorAppointmentStatus.cancelled,
      );
      expect(
        DoctorAppointmentStatusX.fromWire('RESCHEDULED'),
        DoctorAppointmentStatus.rescheduled,
      );
      expect(
        DoctorAppointmentStatusX.fromWire('COMPLETED'),
        DoctorAppointmentStatus.completed,
      );
      // HELD/EXPIRED are pre-confirmation states a doctor never sees.
      expect(
        DoctorAppointmentStatusX.fromWire('HELD'),
        DoctorAppointmentStatus.other,
      );
      expect(
        DoctorAppointmentStatusX.fromWire(null),
        DoctorAppointmentStatus.other,
      );
    });

    test('only actionable while CONFIRMED', () {
      expect(_FakeRepo._appointment.isActionable, isTrue);
    });
  });
}
