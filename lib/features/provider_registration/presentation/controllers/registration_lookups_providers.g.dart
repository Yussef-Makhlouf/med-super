// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_lookups_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Specialties + cities fetched once from the mock/API catalog — never
/// hardcoded inside a screen.

@ProviderFor(registrationLookups)
final registrationLookupsProvider = RegistrationLookupsProvider._();

/// Specialties + cities fetched once from the mock/API catalog — never
/// hardcoded inside a screen.

final class RegistrationLookupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<({List<LookupItem> cities, List<LookupItem> specialties})>,
          ({List<LookupItem> cities, List<LookupItem> specialties}),
          FutureOr<({List<LookupItem> cities, List<LookupItem> specialties})>
        >
    with
        $FutureModifier<
          ({List<LookupItem> cities, List<LookupItem> specialties})
        >,
        $FutureProvider<
          ({List<LookupItem> cities, List<LookupItem> specialties})
        > {
  /// Specialties + cities fetched once from the mock/API catalog — never
  /// hardcoded inside a screen.
  RegistrationLookupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registrationLookupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registrationLookupsHash();

  @$internal
  @override
  $FutureProviderElement<
    ({List<LookupItem> cities, List<LookupItem> specialties})
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({List<LookupItem> cities, List<LookupItem> specialties})> create(
    Ref ref,
  ) {
    return registrationLookups(ref);
  }
}

String _$registrationLookupsHash() =>
    r'26b2dcee332cba517cc7d98d4975d05d0bb450eb';
