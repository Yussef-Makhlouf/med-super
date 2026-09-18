import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/clinic_branch_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/clinic_branch_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_branch_repository.dart';
import 'package:med_super/features/provider_profile/domain/usecases/get_clinic_branch_usecase.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`,
/// mirroring `doctor_availability_providers.dart`, so this addition doesn't
/// require a `build_runner` regeneration pass.
final clinicBranchRemoteDatasourceProvider =
    Provider<ClinicBranchRemoteDatasource>(
      (ref) => ClinicBranchRemoteDatasource(ref.watch(dioProvider)),
    );

final clinicBranchRepositoryProvider = Provider<ClinicBranchRepository>(
  (ref) => ClinicBranchRepositoryImpl(
    remote: ref.watch(clinicBranchRemoteDatasourceProvider),
  ),
);

final getClinicBranchUseCaseProvider = Provider<GetClinicBranchUseCase>(
  (ref) => GetClinicBranchUseCase(ref.watch(clinicBranchRepositoryProvider)),
);

final clinicBranchProvider = FutureProvider.family<ClinicBranch, String>((
  ref,
  branchId,
) async {
  final result = await ref.watch(getClinicBranchUseCaseProvider).call(branchId);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}, retry: (retryCount, error) => null);
