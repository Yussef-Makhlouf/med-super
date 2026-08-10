import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/doctor_profile_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/doctor_profile_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_profile_repository.dart';
import 'package:med_super/features/provider_profile/domain/usecases/get_doctor_profile_usecase.dart';

part 'doctor_profile_providers.g.dart';

@riverpod
DoctorProfileRemoteDatasource doctorProfileRemoteDatasource(Ref ref) =>
    DoctorProfileRemoteDatasource(ref.watch(dioProvider));

@riverpod
DoctorProfileRepository doctorProfileRepository(Ref ref) =>
    DoctorProfileRepositoryImpl(
      remote: ref.watch(doctorProfileRemoteDatasourceProvider),
    );

@riverpod
GetDoctorProfileUseCase getDoctorProfileUseCase(Ref ref) =>
    GetDoctorProfileUseCase(ref.watch(doctorProfileRepositoryProvider));

@riverpod
Future<DoctorProfile> doctorProfile(Ref ref, String doctorId) async {
  final result =
      await ref.watch(getDoctorProfileUseCaseProvider).call(doctorId);
  return result.when(
    ok: (value) => value,
    err: (failure) => throw failure,
  );
}
