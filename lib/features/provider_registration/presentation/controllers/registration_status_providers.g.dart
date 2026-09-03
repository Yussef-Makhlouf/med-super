// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `GET /v1/provider/registration/status` via
/// `GetMyDoctorRegistrationStatusUseCase` — the pending-approval screen's
/// only source of truth for "has an Admin verified me yet?", since the
/// local `SettingsKeys.providerRegistrationSubmitted` flag only means "I
/// submitted the form," never "I was approved." `null` means the caller
/// never self-registered as a doctor at all (the endpoint's `404`).
/// Refetched via pull-to-refresh on that screen (autoDispose: navigating
/// away and back re-fetches too).

@ProviderFor(doctorRegistrationStatus)
final doctorRegistrationStatusProvider = DoctorRegistrationStatusProvider._();

/// `GET /v1/provider/registration/status` via
/// `GetMyDoctorRegistrationStatusUseCase` — the pending-approval screen's
/// only source of truth for "has an Admin verified me yet?", since the
/// local `SettingsKeys.providerRegistrationSubmitted` flag only means "I
/// submitted the form," never "I was approved." `null` means the caller
/// never self-registered as a doctor at all (the endpoint's `404`).
/// Refetched via pull-to-refresh on that screen (autoDispose: navigating
/// away and back re-fetches too).

final class DoctorRegistrationStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<DoctorRegistrationStatus?>,
          DoctorRegistrationStatus?,
          FutureOr<DoctorRegistrationStatus?>
        >
    with
        $FutureModifier<DoctorRegistrationStatus?>,
        $FutureProvider<DoctorRegistrationStatus?> {
  /// `GET /v1/provider/registration/status` via
  /// `GetMyDoctorRegistrationStatusUseCase` — the pending-approval screen's
  /// only source of truth for "has an Admin verified me yet?", since the
  /// local `SettingsKeys.providerRegistrationSubmitted` flag only means "I
  /// submitted the form," never "I was approved." `null` means the caller
  /// never self-registered as a doctor at all (the endpoint's `404`).
  /// Refetched via pull-to-refresh on that screen (autoDispose: navigating
  /// away and back re-fetches too).
  DoctorRegistrationStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorRegistrationStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorRegistrationStatusHash();

  @$internal
  @override
  $FutureProviderElement<DoctorRegistrationStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DoctorRegistrationStatus?> create(Ref ref) {
    return doctorRegistrationStatus(ref);
  }
}

String _$doctorRegistrationStatusHash() =>
    r'bc0a126f6355d8f9f829967c192a179003047652';
