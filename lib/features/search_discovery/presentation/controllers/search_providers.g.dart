// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(doctorSearchRemoteDatasource)
final doctorSearchRemoteDatasourceProvider =
    DoctorSearchRemoteDatasourceProvider._();

final class DoctorSearchRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          DoctorSearchRemoteDatasource,
          DoctorSearchRemoteDatasource,
          DoctorSearchRemoteDatasource
        >
    with $Provider<DoctorSearchRemoteDatasource> {
  DoctorSearchRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorSearchRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorSearchRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<DoctorSearchRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DoctorSearchRemoteDatasource create(Ref ref) {
    return doctorSearchRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorSearchRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorSearchRemoteDatasource>(value),
    );
  }
}

String _$doctorSearchRemoteDatasourceHash() =>
    r'3f5935ffd24100b76365010a69cf8be0d36f19ea';

@ProviderFor(doctorSearchRepository)
final doctorSearchRepositoryProvider = DoctorSearchRepositoryProvider._();

final class DoctorSearchRepositoryProvider
    extends
        $FunctionalProvider<
          DoctorSearchRepository,
          DoctorSearchRepository,
          DoctorSearchRepository
        >
    with $Provider<DoctorSearchRepository> {
  DoctorSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorSearchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<DoctorSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DoctorSearchRepository create(Ref ref) {
    return doctorSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorSearchRepository>(value),
    );
  }
}

String _$doctorSearchRepositoryHash() =>
    r'90a8fa14f6e932b0fc135e291eb87394dd783b44';

@ProviderFor(searchDoctorsUseCase)
final searchDoctorsUseCaseProvider = SearchDoctorsUseCaseProvider._();

final class SearchDoctorsUseCaseProvider
    extends
        $FunctionalProvider<
          SearchDoctorsUseCase,
          SearchDoctorsUseCase,
          SearchDoctorsUseCase
        >
    with $Provider<SearchDoctorsUseCase> {
  SearchDoctorsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchDoctorsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchDoctorsUseCaseHash();

  @$internal
  @override
  $ProviderElement<SearchDoctorsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchDoctorsUseCase create(Ref ref) {
    return searchDoctorsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchDoctorsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchDoctorsUseCase>(value),
    );
  }
}

String _$searchDoctorsUseCaseHash() =>
    r'9f7bb41da92c31953f3d3412295ea71a844f312f';

@ProviderFor(DoctorSearchController)
final doctorSearchControllerProvider = DoctorSearchControllerProvider._();

final class DoctorSearchControllerProvider
    extends $NotifierProvider<DoctorSearchController, DoctorSearchParams> {
  DoctorSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorSearchControllerHash();

  @$internal
  @override
  DoctorSearchController create() => DoctorSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorSearchParams value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorSearchParams>(value),
    );
  }
}

String _$doctorSearchControllerHash() =>
    r'7c5e6366eb5a9c3bde4c9fa1cc4798e75f132cd3';

abstract class _$DoctorSearchController extends $Notifier<DoctorSearchParams> {
  DoctorSearchParams build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DoctorSearchParams, DoctorSearchParams>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DoctorSearchParams, DoctorSearchParams>,
              DoctorSearchParams,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(doctorSearchResults)
final doctorSearchResultsProvider = DoctorSearchResultsProvider._();

final class DoctorSearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DoctorSearchResult>,
          DoctorSearchResult,
          FutureOr<DoctorSearchResult>
        >
    with
        $FutureModifier<DoctorSearchResult>,
        $FutureProvider<DoctorSearchResult> {
  DoctorSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorSearchResultsHash();

  @$internal
  @override
  $FutureProviderElement<DoctorSearchResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DoctorSearchResult> create(Ref ref) {
    return doctorSearchResults(ref);
  }
}

String _$doctorSearchResultsHash() =>
    r'f0002064fd81f4e8763e4487359741b4f3f1e00e';
