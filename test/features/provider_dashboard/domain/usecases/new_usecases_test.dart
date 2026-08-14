import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/clinic_settings.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_account_profile.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/change_password_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/clinic_settings_usecases.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/update_doctor_account_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/upload_avatar_usecase.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';

class MockProviderDashboardRepo implements ProviderDashboardRepository {
  @override
  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    required String name,
    required String specialty,
    required int yearsOfExperience,
    required String bio,
  }) async {
    return Result.ok(
      DoctorAccountProfile(
        id: 'doc-001',
        name: name,
        specialty: specialty,
        hospitalName: 'Hospital',
        yearsOfExperience: yearsOfExperience,
        bio: bio,
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
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<DoctorAccountProfile>> uploadAvatar(String filePath) async {
    return const Result.ok(
      DoctorAccountProfile(
        id: 'doc-001',
        name: 'Doctor Name',
        specialty: 'Specialty',
        hospitalName: 'Hospital',
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

  test('UpdateDoctorAccountUseCase updates account profile', () async {
    final useCase = UpdateDoctorAccountUseCase(repo);
    final res = await useCase.call(
      name: 'د. خالد',
      specialty: 'قلب',
      yearsOfExperience: 15,
      bio: 'Bio text',
    );
    expect(res.isOk, isTrue);
    res.when(
      ok: (val) => expect(val.name, 'د. خالد'),
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

  test('ChangePasswordUseCase succeeds', () async {
    final useCase = ChangePasswordUseCase(repo);
    final res = await useCase.call(
      currentPassword: 'old',
      newPassword: 'newpassword',
    );
    expect(res.isOk, isTrue);
  });

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
