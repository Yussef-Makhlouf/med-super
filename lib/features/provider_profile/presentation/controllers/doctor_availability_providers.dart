import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/doctor_slots_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/doctor_slots_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_slots_repository.dart';
import 'package:med_super/features/provider_profile/domain/usecases/get_doctor_availability_usecase.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`, so
/// this Phase 3 addition doesn't require a `build_runner` regeneration pass.
final doctorSlotsRemoteDatasourceProvider =
    Provider<DoctorSlotsRemoteDatasource>(
      (ref) => DoctorSlotsRemoteDatasource(ref.watch(dioProvider)),
    );

final doctorSlotsRepositoryProvider = Provider<DoctorSlotsRepository>(
  (ref) => DoctorSlotsRepositoryImpl(
    remote: ref.watch(doctorSlotsRemoteDatasourceProvider),
  ),
);

final getDoctorAvailabilityUseCaseProvider =
    Provider<GetDoctorAvailabilityUseCase>(
      (ref) => GetDoctorAvailabilityUseCase(
        ref.watch(doctorSlotsRepositoryProvider),
      ),
    );

typedef DoctorAvailabilityParams = ({
  String doctorId,
  String clinicBranchId,
  String? ianaTimezone,
});

final doctorAvailabilityProvider =
    FutureProvider.family<List<AvailableDay>, DoctorAvailabilityParams>((
      ref,
      params,
    ) async {
      final result = await ref
          .watch(getDoctorAvailabilityUseCaseProvider)
          .call(
            doctorId: params.doctorId,
            clinicBranchId: params.clinicBranchId,
            ianaTimezone: params.ianaTimezone,
          );
      return result.when(ok: (value) => value, err: (failure) => throw failure);
    });
