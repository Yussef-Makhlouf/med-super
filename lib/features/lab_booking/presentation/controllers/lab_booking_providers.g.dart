// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_booking_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(labCatalogRemoteDatasource)
final labCatalogRemoteDatasourceProvider =
    LabCatalogRemoteDatasourceProvider._();

final class LabCatalogRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          LabCatalogRemoteDatasource,
          LabCatalogRemoteDatasource,
          LabCatalogRemoteDatasource
        >
    with $Provider<LabCatalogRemoteDatasource> {
  LabCatalogRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labCatalogRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labCatalogRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<LabCatalogRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LabCatalogRemoteDatasource create(Ref ref) {
    return labCatalogRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabCatalogRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabCatalogRemoteDatasource>(value),
    );
  }
}

String _$labCatalogRemoteDatasourceHash() =>
    r'1e677bcd42cace9d86c9a0869a9ef60a35a3de63';

@ProviderFor(labCatalogRepository)
final labCatalogRepositoryProvider = LabCatalogRepositoryProvider._();

final class LabCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          LabCatalogRepository,
          LabCatalogRepository,
          LabCatalogRepository
        >
    with $Provider<LabCatalogRepository> {
  LabCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labCatalogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<LabCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LabCatalogRepository create(Ref ref) {
    return labCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabCatalogRepository>(value),
    );
  }
}

String _$labCatalogRepositoryHash() =>
    r'7fd95a526122d74e7252231177521272280a92c9';

@ProviderFor(getLabCatalogUseCase)
final getLabCatalogUseCaseProvider = GetLabCatalogUseCaseProvider._();

final class GetLabCatalogUseCaseProvider
    extends
        $FunctionalProvider<
          GetLabCatalogUseCase,
          GetLabCatalogUseCase,
          GetLabCatalogUseCase
        >
    with $Provider<GetLabCatalogUseCase> {
  GetLabCatalogUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getLabCatalogUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getLabCatalogUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetLabCatalogUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetLabCatalogUseCase create(Ref ref) {
    return getLabCatalogUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetLabCatalogUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetLabCatalogUseCase>(value),
    );
  }
}

String _$getLabCatalogUseCaseHash() =>
    r'8d3fabc1049ba1773cb19af911c216a9a8e25b14';

@ProviderFor(labCatalog)
final labCatalogProvider = LabCatalogProvider._();

final class LabCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<LabCatalog>,
          LabCatalog,
          FutureOr<LabCatalog>
        >
    with $FutureModifier<LabCatalog>, $FutureProvider<LabCatalog> {
  LabCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labCatalogHash();

  @$internal
  @override
  $FutureProviderElement<LabCatalog> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LabCatalog> create(Ref ref) {
    return labCatalog(ref);
  }
}

String _$labCatalogHash() => r'339fb736e44297ad598eddffcbe1716d06cab347';

/// Active category chip filter ('all' package chip is pre-selected by design).

@ProviderFor(ActiveLabCategory)
final activeLabCategoryProvider = ActiveLabCategoryProvider._();

/// Active category chip filter ('all' package chip is pre-selected by design).
final class ActiveLabCategoryProvider
    extends $NotifierProvider<ActiveLabCategory, String?> {
  /// Active category chip filter ('all' package chip is pre-selected by design).
  ActiveLabCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeLabCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeLabCategoryHash();

  @$internal
  @override
  ActiveLabCategory create() => ActiveLabCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeLabCategoryHash() => r'a351276d16ab9c8ed826f821d5b49234bb451d5f';

/// Active category chip filter ('all' package chip is pre-selected by design).

abstract class _$ActiveLabCategory extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Free-text search query typed into the lab-tests search box.

@ProviderFor(LabSearchQuery)
final labSearchQueryProvider = LabSearchQueryProvider._();

/// Free-text search query typed into the lab-tests search box.
final class LabSearchQueryProvider
    extends $NotifierProvider<LabSearchQuery, String> {
  /// Free-text search query typed into the lab-tests search box.
  LabSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labSearchQueryHash();

  @$internal
  @override
  LabSearchQuery create() => LabSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$labSearchQueryHash() => r'6b899b506b1443d3f26d28bb13c7b27174423bc9';

/// Free-text search query typed into the lab-tests search box.

abstract class _$LabSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Test/package selection state — Set of selected [LabTest.id].

@ProviderFor(SelectedLabTests)
final selectedLabTestsProvider = SelectedLabTestsProvider._();

/// Test/package selection state — Set of selected [LabTest.id].
final class SelectedLabTestsProvider
    extends $NotifierProvider<SelectedLabTests, Set<String>> {
  /// Test/package selection state — Set of selected [LabTest.id].
  SelectedLabTestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedLabTestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedLabTestsHash();

  @$internal
  @override
  SelectedLabTests create() => SelectedLabTests();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedLabTestsHash() => r'87327f8ce87021a038feec5dbf43d1d258e81624';

/// Test/package selection state — Set of selected [LabTest.id].

abstract class _$SelectedLabTests extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Live total price of the current selection.

@ProviderFor(selectedLabTestsTotal)
final selectedLabTestsTotalProvider = SelectedLabTestsTotalProvider._();

/// Live total price of the current selection.

final class SelectedLabTestsTotalProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Live total price of the current selection.
  SelectedLabTestsTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedLabTestsTotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedLabTestsTotalHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return selectedLabTestsTotal(ref);
  }
}

String _$selectedLabTestsTotalHash() =>
    r'ab6b0021b799b43dfeaff849eee0c1eb0c5b3c93';
