// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providerRegistrationRemoteDatasource)
final providerRegistrationRemoteDatasourceProvider =
    ProviderRegistrationRemoteDatasourceProvider._();

final class ProviderRegistrationRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          ProviderRegistrationRemoteDatasource,
          ProviderRegistrationRemoteDatasource,
          ProviderRegistrationRemoteDatasource
        >
    with $Provider<ProviderRegistrationRemoteDatasource> {
  ProviderRegistrationRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerRegistrationRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$providerRegistrationRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<ProviderRegistrationRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProviderRegistrationRemoteDatasource create(Ref ref) {
    return providerRegistrationRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderRegistrationRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ProviderRegistrationRemoteDatasource>(value),
    );
  }
}

String _$providerRegistrationRemoteDatasourceHash() =>
    r'59f44a52298cc5bda5c23e4596d1b1b2cac08196';

@ProviderFor(providerRegistrationRepository)
final providerRegistrationRepositoryProvider =
    ProviderRegistrationRepositoryProvider._();

final class ProviderRegistrationRepositoryProvider
    extends
        $FunctionalProvider<
          ProviderRegistrationRepository,
          ProviderRegistrationRepository,
          ProviderRegistrationRepository
        >
    with $Provider<ProviderRegistrationRepository> {
  ProviderRegistrationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerRegistrationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerRegistrationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProviderRegistrationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProviderRegistrationRepository create(Ref ref) {
    return providerRegistrationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderRegistrationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProviderRegistrationRepository>(
        value,
      ),
    );
  }
}

String _$providerRegistrationRepositoryHash() =>
    r'476a87d745690514816ab65638d5a08074f544a2';

@ProviderFor(submitRegistrationUseCase)
final submitRegistrationUseCaseProvider = SubmitRegistrationUseCaseProvider._();

final class SubmitRegistrationUseCaseProvider
    extends
        $FunctionalProvider<
          SubmitRegistrationUseCase,
          SubmitRegistrationUseCase,
          SubmitRegistrationUseCase
        >
    with $Provider<SubmitRegistrationUseCase> {
  SubmitRegistrationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitRegistrationUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitRegistrationUseCaseHash();

  @$internal
  @override
  $ProviderElement<SubmitRegistrationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubmitRegistrationUseCase create(Ref ref) {
    return submitRegistrationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmitRegistrationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmitRegistrationUseCase>(value),
    );
  }
}

String _$submitRegistrationUseCaseHash() =>
    r'c2db0c021efecd88b51c6ba10aa20e0ee5d32347';

/// Holds the in-progress multi-step draft, auto-saved to Hive on every change
/// so the flow survives an app restart before final submission.

@ProviderFor(RegistrationFormController)
final registrationFormControllerProvider =
    RegistrationFormControllerProvider._();

/// Holds the in-progress multi-step draft, auto-saved to Hive on every change
/// so the flow survives an app restart before final submission.
final class RegistrationFormControllerProvider
    extends
        $NotifierProvider<RegistrationFormController, DoctorRegistrationDraft> {
  /// Holds the in-progress multi-step draft, auto-saved to Hive on every change
  /// so the flow survives an app restart before final submission.
  RegistrationFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registrationFormControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registrationFormControllerHash();

  @$internal
  @override
  RegistrationFormController create() => RegistrationFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorRegistrationDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorRegistrationDraft>(value),
    );
  }
}

String _$registrationFormControllerHash() =>
    r'6a9eb84ec5493a06c0ba756f113e6d572c5bafa3';

/// Holds the in-progress multi-step draft, auto-saved to Hive on every change
/// so the flow survives an app restart before final submission.

abstract class _$RegistrationFormController
    extends $Notifier<DoctorRegistrationDraft> {
  DoctorRegistrationDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<DoctorRegistrationDraft, DoctorRegistrationDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DoctorRegistrationDraft, DoctorRegistrationDraft>,
              DoctorRegistrationDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
