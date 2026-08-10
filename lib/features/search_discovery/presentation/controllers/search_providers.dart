import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/search_discovery/data/datasources/remote/doctor_search_remote_datasource.dart';
import 'package:med_super/features/search_discovery/data/repositories/doctor_search_repository_impl.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/repositories/doctor_search_repository.dart';
import 'package:med_super/features/search_discovery/domain/usecases/search_doctors_usecase.dart';

part 'search_providers.g.dart';

@riverpod
DoctorSearchRemoteDatasource doctorSearchRemoteDatasource(Ref ref) =>
    DoctorSearchRemoteDatasource(ref.watch(dioProvider));

@riverpod
DoctorSearchRepository doctorSearchRepository(Ref ref) =>
    DoctorSearchRepositoryImpl(
      remote: ref.watch(doctorSearchRemoteDatasourceProvider),
    );

@riverpod
SearchDoctorsUseCase searchDoctorsUseCase(Ref ref) =>
    SearchDoctorsUseCase(ref.watch(doctorSearchRepositoryProvider));

class DoctorSearchParams {
  const DoctorSearchParams({
    this.query = '',
    this.specialty,
    this.sort = DoctorSort.topRated,
  });

  final String query;
  final String? specialty;
  final DoctorSort sort;

  DoctorSearchParams copyWith({
    String? query,
    String? specialty,
    DoctorSort? sort,
    bool clearSpecialty = false,
  }) =>
      DoctorSearchParams(
        query: query ?? this.query,
        specialty: clearSpecialty ? null : (specialty ?? this.specialty),
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is DoctorSearchParams &&
      other.query == query &&
      other.specialty == specialty &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, specialty, sort);
}

@riverpod
class DoctorSearchController extends _$DoctorSearchController {
  @override
  DoctorSearchParams build() => const DoctorSearchParams();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSpecialty(String? specialty) => state = specialty == null
      ? state.copyWith(clearSpecialty: true)
      : state.copyWith(specialty: specialty);

  void setSort(DoctorSort sort) => state = state.copyWith(sort: sort);
}

@riverpod
Future<DoctorSearchResult> doctorSearchResults(Ref ref) async {
  final params = ref.watch(doctorSearchControllerProvider);
  final result = await ref.watch(searchDoctorsUseCaseProvider).call(
        query: params.query,
        specialty: params.specialty,
        sort: params.sort,
      );
  return result.when(
    ok: (value) => value,
    err: (failure) => throw failure,
  );
}
