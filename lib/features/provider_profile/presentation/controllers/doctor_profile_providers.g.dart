// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(doctorProfileRemoteDatasource)
final doctorProfileRemoteDatasourceProvider =
    DoctorProfileRemoteDatasourceProvider._();

final class DoctorProfileRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          DoctorProfileRemoteDatasource,
          DoctorProfileRemoteDatasource,
          DoctorProfileRemoteDatasource
        >
    with $Provider<DoctorProfileRemoteDatasource> {
  DoctorProfileRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorProfileRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorProfileRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<DoctorProfileRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DoctorProfileRemoteDatasource create(Ref ref) {
    return doctorProfileRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorProfileRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorProfileRemoteDatasource>(
        value,
      ),
    );
  }
}

String _$doctorProfileRemoteDatasourceHash() =>
    r'4663cf59ddee7adc6e264c0fed6f10e1e3d9c83d';

@ProviderFor(doctorProfileRepository)
final doctorProfileRepositoryProvider = DoctorProfileRepositoryProvider._();

final class DoctorProfileRepositoryProvider
    extends
        $FunctionalProvider<
          DoctorProfileRepository,
          DoctorProfileRepository,
          DoctorProfileRepository
        >
    with $Provider<DoctorProfileRepository> {
  DoctorProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<DoctorProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DoctorProfileRepository create(Ref ref) {
    return doctorProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorProfileRepository>(value),
    );
  }
}

String _$doctorProfileRepositoryHash() =>
    r'6bf833b7c8de8844d092fb1d4cf7754ac01032bb';

@ProviderFor(getDoctorProfileUseCase)
final getDoctorProfileUseCaseProvider = GetDoctorProfileUseCaseProvider._();

final class GetDoctorProfileUseCaseProvider
    extends
        $FunctionalProvider<
          GetDoctorProfileUseCase,
          GetDoctorProfileUseCase,
          GetDoctorProfileUseCase
        >
    with $Provider<GetDoctorProfileUseCase> {
  GetDoctorProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getDoctorProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getDoctorProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetDoctorProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetDoctorProfileUseCase create(Ref ref) {
    return getDoctorProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetDoctorProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetDoctorProfileUseCase>(value),
    );
  }
}

String _$getDoctorProfileUseCaseHash() =>
    r'1be532cdc5dec3f4ddbc192d6604559c12889bbd';

@ProviderFor(doctorProfile)
final doctorProfileProvider = DoctorProfileFamily._();

final class DoctorProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<DoctorProfile>,
          DoctorProfile,
          FutureOr<DoctorProfile>
        >
    with $FutureModifier<DoctorProfile>, $FutureProvider<DoctorProfile> {
  DoctorProfileProvider._({
    required DoctorProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'doctorProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$doctorProfileHash();

  @override
  String toString() {
    return r'doctorProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DoctorProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DoctorProfile> create(Ref ref) {
    final argument = this.argument as String;
    return doctorProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DoctorProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$doctorProfileHash() => r'7ecccc250beb6c91e103035052503520fcc70966';

final class DoctorProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DoctorProfile>, String> {
  DoctorProfileFamily._()
    : super(
        retry: null,
        name: r'doctorProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DoctorProfileProvider call(String doctorId) =>
      DoctorProfileProvider._(argument: doctorId, from: this);

  @override
  String toString() => r'doctorProfileProvider';
}
