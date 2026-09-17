import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/specialties/data/datasources/remote/specialties_remote_datasource.dart';
import 'package:med_super/core/specialties/data/repositories/specialties_repository_impl.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/domain/repositories/specialties_repository.dart';
import 'package:med_super/core/specialties/domain/usecases/list_specialties_usecase.dart';

/// Plain (non-codegen) Riverpod providers — mirrors
/// `doctor_availability_providers.dart`'s reasoning: no `@riverpod` here so
/// this addition doesn't require a `build_runner` regeneration pass.
final specialtiesRemoteDatasourceProvider =
    Provider<SpecialtiesRemoteDatasource>(
      (ref) => SpecialtiesRemoteDatasource(ref.watch(dioProvider)),
    );

final specialtiesRepositoryProvider = Provider<SpecialtiesRepository>(
  (ref) => SpecialtiesRepositoryImpl(
    remote: ref.watch(specialtiesRemoteDatasourceProvider),
  ),
);

final listSpecialtiesUseCaseProvider = Provider<ListSpecialtiesUseCase>(
  (ref) => ListSpecialtiesUseCase(ref.watch(specialtiesRepositoryProvider)),
);

/// The full specialty list — shared by the patient home screen's
/// specialties row and (via `initialSpecialty`) the search filter. No
/// `.family` needed: the endpoint takes no parameters.
final specialtiesProvider = FutureProvider<List<Specialty>>((ref) async {
  final result = await ref.watch(listSpecialtiesUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}, retry: (retryCount, error) => null);
