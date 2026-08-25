import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/clinic_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/clinic_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_repository.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`,
/// mirroring `doctor_availability_providers.dart`, so this addition doesn't
/// require a `build_runner` regeneration pass.
final clinicRemoteDatasourceProvider = Provider<ClinicRemoteDatasource>(
  (ref) => ClinicRemoteDatasource(ref.watch(dioProvider)),
);

final clinicRepositoryProvider = Provider<ClinicRepository>(
  (ref) =>
      ClinicRepositoryImpl(remote: ref.watch(clinicRemoteDatasourceProvider)),
);

final clinicProfileProvider = FutureProvider.family<ClinicProfile, String>((
  ref,
  clinicId,
) async {
  final result = await ref
      .watch(clinicRepositoryProvider)
      .getClinicProfile(clinicId);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}, retry: (retryCount, error) => null);
