// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_partner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(labBookingRemoteDatasource)
final labBookingRemoteDatasourceProvider =
    LabBookingRemoteDatasourceProvider._();

final class LabBookingRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          LabBookingRemoteDatasource,
          LabBookingRemoteDatasource,
          LabBookingRemoteDatasource
        >
    with $Provider<LabBookingRemoteDatasource> {
  LabBookingRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labBookingRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labBookingRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<LabBookingRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LabBookingRemoteDatasource create(Ref ref) {
    return labBookingRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabBookingRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabBookingRemoteDatasource>(value),
    );
  }
}

String _$labBookingRemoteDatasourceHash() =>
    r'7f85cea9627f1b5e2d6326889a2b51ca466b6634';

@ProviderFor(labBookingRepository)
final labBookingRepositoryProvider = LabBookingRepositoryProvider._();

final class LabBookingRepositoryProvider
    extends
        $FunctionalProvider<
          LabBookingRepository,
          LabBookingRepository,
          LabBookingRepository
        >
    with $Provider<LabBookingRepository> {
  LabBookingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labBookingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labBookingRepositoryHash();

  @$internal
  @override
  $ProviderElement<LabBookingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LabBookingRepository create(Ref ref) {
    return labBookingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabBookingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabBookingRepository>(value),
    );
  }
}

String _$labBookingRepositoryHash() =>
    r'e50189aae42a04aef954c8e5d2270ba484fb5bea';

@ProviderFor(getLabPartnersUseCase)
final getLabPartnersUseCaseProvider = GetLabPartnersUseCaseProvider._();

final class GetLabPartnersUseCaseProvider
    extends
        $FunctionalProvider<
          GetLabPartnersUseCase,
          GetLabPartnersUseCase,
          GetLabPartnersUseCase
        >
    with $Provider<GetLabPartnersUseCase> {
  GetLabPartnersUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getLabPartnersUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getLabPartnersUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetLabPartnersUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetLabPartnersUseCase create(Ref ref) {
    return getLabPartnersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetLabPartnersUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetLabPartnersUseCase>(value),
    );
  }
}

String _$getLabPartnersUseCaseHash() =>
    r'd2943056ddb910084cea479ce8f2886689bf09b8';

@ProviderFor(confirmLabBookingUseCase)
final confirmLabBookingUseCaseProvider = ConfirmLabBookingUseCaseProvider._();

final class ConfirmLabBookingUseCaseProvider
    extends
        $FunctionalProvider<
          ConfirmLabBookingUseCase,
          ConfirmLabBookingUseCase,
          ConfirmLabBookingUseCase
        >
    with $Provider<ConfirmLabBookingUseCase> {
  ConfirmLabBookingUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confirmLabBookingUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confirmLabBookingUseCaseHash();

  @$internal
  @override
  $ProviderElement<ConfirmLabBookingUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConfirmLabBookingUseCase create(Ref ref) {
    return confirmLabBookingUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfirmLabBookingUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfirmLabBookingUseCase>(value),
    );
  }
}

String _$confirmLabBookingUseCaseHash() =>
    r'5261f2f2025add50f20b7d4b6ec5a0fd00d89da1';

/// Sort order for the lab-partner list — defaults to "nearest" per Figma.

@ProviderFor(LabSortController)
final labSortControllerProvider = LabSortControllerProvider._();

/// Sort order for the lab-partner list — defaults to "nearest" per Figma.
final class LabSortControllerProvider
    extends $NotifierProvider<LabSortController, LabSortOption> {
  /// Sort order for the lab-partner list — defaults to "nearest" per Figma.
  LabSortControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labSortControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labSortControllerHash();

  @$internal
  @override
  LabSortController create() => LabSortController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabSortOption value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabSortOption>(value),
    );
  }
}

String _$labSortControllerHash() => r'670dbbafbb66fda445468d25b4904892e76fd32c';

/// Sort order for the lab-partner list — defaults to "nearest" per Figma.

abstract class _$LabSortController extends $Notifier<LabSortOption> {
  LabSortOption build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LabSortOption, LabSortOption>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LabSortOption, LabSortOption>,
              LabSortOption,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(labPartners)
final labPartnersProvider = LabPartnersProvider._();

final class LabPartnersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LabPartner>>,
          List<LabPartner>,
          FutureOr<List<LabPartner>>
        >
    with $FutureModifier<List<LabPartner>>, $FutureProvider<List<LabPartner>> {
  LabPartnersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labPartnersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labPartnersHash();

  @$internal
  @override
  $FutureProviderElement<List<LabPartner>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LabPartner>> create(Ref ref) {
    return labPartners(ref);
  }
}

String _$labPartnersHash() => r'1eeb1b62723fca537d17400982b816f8ec1e3e71';

/// Explicitly chosen lab id — null means "not chosen yet, default to the
/// first (nearest) result", matching the Figma state where the top card is
/// pre-selected without any tap.

@ProviderFor(SelectedLabPartner)
final selectedLabPartnerProvider = SelectedLabPartnerProvider._();

/// Explicitly chosen lab id — null means "not chosen yet, default to the
/// first (nearest) result", matching the Figma state where the top card is
/// pre-selected without any tap.
final class SelectedLabPartnerProvider
    extends $NotifierProvider<SelectedLabPartner, String?> {
  /// Explicitly chosen lab id — null means "not chosen yet, default to the
  /// first (nearest) result", matching the Figma state where the top card is
  /// pre-selected without any tap.
  SelectedLabPartnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedLabPartnerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedLabPartnerHash();

  @$internal
  @override
  SelectedLabPartner create() => SelectedLabPartner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedLabPartnerHash() =>
    r'0e4cb603f8dfc0dfbe37eb744750999c7ac52895';

/// Explicitly chosen lab id — null means "not chosen yet, default to the
/// first (nearest) result", matching the Figma state where the top card is
/// pre-selected without any tap.

abstract class _$SelectedLabPartner extends $Notifier<String?> {
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
