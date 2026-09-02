import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/clinic_settings.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_account_profile.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/clinic_settings_usecases.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/update_doctor_account_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/upload_avatar_usecase.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';

/// Renamed from `new_usecases_test.dart` (2026-09-02) — that file tested a
/// `changePassword` repository method and `ChangePasswordUseCase` that never
/// actually existed in `ProviderDashboardRepository`/this directory (the
/// import didn't resolve), and constructed `DoctorAccountProfile`/
/// `updateDoctorAccount` with a shape (`name`/`specialty`/`hospitalName`
/// required) that predates the real `GET /v1/doctors/me` wiring
/// (`clinic-reservations` File 12 Part 45) — `hospitalName` was dropped,
/// `licenseNumber`/`phone` are now required, and `updateDoctorAccount` only
/// ever touches `bio`/`degree`/`yearsOfExperience`. This file only covers
/// the use-cases that are actually implemented.
class MockProviderDashboardRepo implements ProviderDashboardRepository {
  @override
  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  }) async {
    return Result.ok(
      DoctorAccountProfile(
        id: 'doc-001',
        name: 'د. خالد',
        specialty: 'قلب',
        licenseNumber: 'LIC-001',
        phone: '+201000000000',
        bio: bio ?? '',
        degree: degree,
        yearsOfExperience: yearsOfExperience,
      ),
    );
  }

  @override
  Future<Result<ClinicSettings>> getClinicSettings() async {
    return const Result.ok(
      ClinicSettings(
        clinicName: 'Test Clinic',
        address: 'Test Address',
        phone: '123456',
        email: 'test@test.com',
      ),
    );
  }

  @override
  Future<Result<ClinicSettings>> updateClinicSettings(
    ClinicSettings settings,
  ) async {
    return Result.ok(settings);
  }

  @override
  Future<Result<List<ClinicWorkingDay>>> getDoctorSchedule() async {
    return const Result.ok([]);
  }

  @override
  Future<Result<List<ClinicWorkingDay>>> updateDoctorSchedule(
    List<ClinicWorkingDay> workingDays,
  ) async {
    return Result.ok(workingDays);
  }

  @override
  Future<Result<DoctorAccountProfile>> uploadAvatar(String filePath) async {
    return const Result.ok(
      DoctorAccountProfile(
        id: 'doc-001',
        name: 'Doctor Name',
        specialty: 'Specialty',
        licenseNumber: 'LIC-001',
        phone: '+201000000000',
        avatarUrl: 'https://example.com/avatar.jpg',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockProviderDashboardRepo repo;

  setUp(() {
    repo = MockProviderDashboardRepo();
  });

  test('UpdateDoctorAccountUseCase updates bio/degree/yearsOfExperience', () async {
    final useCase = UpdateDoctorAccountUseCase(repo);
    final res = await useCase.call(
      bio: 'Bio text',
      degree: 'MBBS',
      yearsOfExperience: 15,
    );
    expect(res.isOk, isTrue);
    res.when(
      ok: (val) {
        expect(val.bio, 'Bio text');
        expect(val.degree, 'MBBS');
        expect(val.yearsOfExperience, 15);
      },
      err: (e) => fail(e.toString()),
    );
  });

  test(
    'GetClinicSettingsUseCase and UpdateClinicSettingsUseCase succeed',
    () async {
      final getUseCase = GetClinicSettingsUseCase(repo);
      final updateUseCase = UpdateClinicSettingsUseCase(repo);

      final getRes = await getUseCase.call();
      expect(getRes.isOk, isTrue);
      getRes.when(
        ok: (val) => expect(val.clinicName, 'Test Clinic'),
        err: (e) => fail(e.toString()),
      );

      final updateRes = await updateUseCase.call(
        const ClinicSettings(
          clinicName: 'New Clinic',
          address: 'New Addr',
          phone: '999',
          email: 'new@test.com',
        ),
      );
      expect(updateRes.isOk, isTrue);
      updateRes.when(
        ok: (val) => expect(val.clinicName, 'New Clinic'),
        err: (e) => fail(e.toString()),
      );
    },
  );

  test('UploadAvatarUseCase succeeds', () async {
    final useCase = UploadAvatarUseCase(repo);
    final res = await useCase.call('test.jpg');
    expect(res.isOk, isTrue);
    res.when(
      ok: (val) => expect(val.avatarUrl, 'https://example.com/avatar.jpg'),
      err: (e) => fail(e.toString()),
    );
  });
}
