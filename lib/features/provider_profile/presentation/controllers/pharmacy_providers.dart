import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/pharmacy_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/pharmacy_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_repository.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`,
/// mirroring `doctor_availability_providers.dart`/`clinic_providers.dart`, so
/// this addition doesn't require a `build_runner` regeneration pass.
final pharmacyRemoteDatasourceProvider = Provider<PharmacyRemoteDatasource>(
  (ref) => PharmacyRemoteDatasource(ref.watch(dioProvider)),
);

final pharmacyRepositoryProvider = Provider<PharmacyRepository>(
  (ref) => PharmacyRepositoryImpl(
    remote: ref.watch(pharmacyRemoteDatasourceProvider),
  ),
);

final pharmacyProfileProvider = FutureProvider.family<PharmacyProfile, String>(
  (ref, pharmacyId) async {
    final result = await ref
        .watch(pharmacyRepositoryProvider)
        .getPharmacyProfile(pharmacyId);
    return result.when(ok: (value) => value, err: (failure) => throw failure);
  },
  retry: (retryCount, error) => null,
);
