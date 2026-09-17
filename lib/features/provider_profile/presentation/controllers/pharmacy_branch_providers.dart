import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/pharmacy_branch_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/pharmacy_branch_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_branch_repository.dart';
import 'package:med_super/features/provider_profile/domain/usecases/get_pharmacy_branch_usecase.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`, so
/// this addition doesn't require a `build_runner` regeneration pass (mirrors
/// `provider_profile/presentation/controllers/doctor_availability_providers.dart`).
final pharmacyBranchRemoteDatasourceProvider =
    Provider<PharmacyBranchRemoteDatasource>(
      (ref) => PharmacyBranchRemoteDatasource(ref.watch(dioProvider)),
    );

final pharmacyBranchRepositoryProvider = Provider<PharmacyBranchRepository>(
  (ref) => PharmacyBranchRepositoryImpl(
    remote: ref.watch(pharmacyBranchRemoteDatasourceProvider),
  ),
);

final getPharmacyBranchUseCaseProvider = Provider<GetPharmacyBranchUseCase>(
  (ref) =>
      GetPharmacyBranchUseCase(ref.watch(pharmacyBranchRepositoryProvider)),
);

final pharmacyBranchProvider =
    FutureProvider.family<PharmacyBranch, String>((ref, branchId) async {
      final result = await ref
          .watch(getPharmacyBranchUseCaseProvider)
          .call(branchId);
      return result.when(ok: (value) => value, err: (failure) => throw failure);
    }, retry: (retryCount, error) => null);
