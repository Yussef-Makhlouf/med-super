// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_upload_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).

@ProviderFor(UploadedLabRequestImages)
final uploadedLabRequestImagesProvider = UploadedLabRequestImagesProvider._();

/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).
final class UploadedLabRequestImagesProvider
    extends $NotifierProvider<UploadedLabRequestImages, List<LabRequestImage>> {
  /// Images the patient has attached to the lab request on screen 1
  /// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
  /// hard requirement before the "اختيار المختبر" CTA activates (see
  /// [canContinueFromUploadProvider]).
  UploadedLabRequestImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadedLabRequestImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadedLabRequestImagesHash();

  @$internal
  @override
  UploadedLabRequestImages create() => UploadedLabRequestImages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LabRequestImage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LabRequestImage>>(value),
    );
  }
}

String _$uploadedLabRequestImagesHash() =>
    r'e01bc6da2a9a4466603f424f39ebcd46178f92cb';

/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).

abstract class _$UploadedLabRequestImages
    extends $Notifier<List<LabRequestImage>> {
  List<LabRequestImage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<LabRequestImage>, List<LabRequestImage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LabRequestImage>, List<LabRequestImage>>,
              List<LabRequestImage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the Figma mockup shows a card pre-selected, but the
/// plan explicitly calls for no default so the continue CTA stays disabled
/// until the patient makes an explicit choice.

@ProviderFor(SelectedLabServiceType)
final selectedLabServiceTypeProvider = SelectedLabServiceTypeProvider._();

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the Figma mockup shows a card pre-selected, but the
/// plan explicitly calls for no default so the continue CTA stays disabled
/// until the patient makes an explicit choice.
final class SelectedLabServiceTypeProvider
    extends $NotifierProvider<SelectedLabServiceType, LabServiceType?> {
  /// Which service type ("نوع الخدمة") the patient picked. Deliberately has
  /// no default value — the Figma mockup shows a card pre-selected, but the
  /// plan explicitly calls for no default so the continue CTA stays disabled
  /// until the patient makes an explicit choice.
  SelectedLabServiceTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedLabServiceTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedLabServiceTypeHash();

  @$internal
  @override
  SelectedLabServiceType create() => SelectedLabServiceType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabServiceType? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabServiceType?>(value),
    );
  }
}

String _$selectedLabServiceTypeHash() =>
    r'7bb373864e5addd7d4fa130065d26c83f864c2bc';

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the Figma mockup shows a card pre-selected, but the
/// plan explicitly calls for no default so the continue CTA stays disabled
/// until the patient makes an explicit choice.

abstract class _$SelectedLabServiceType extends $Notifier<LabServiceType?> {
  LabServiceType? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LabServiceType?, LabServiceType?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LabServiceType?, LabServiceType?>,
              LabServiceType?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// True once both screen-1 disable-conditions are satisfied: at least one
/// image attached AND a service type chosen. Drives the enabled/disabled
/// state of the "اختيار المختبر" bottom CTA.

@ProviderFor(canContinueFromUpload)
final canContinueFromUploadProvider = CanContinueFromUploadProvider._();

/// True once both screen-1 disable-conditions are satisfied: at least one
/// image attached AND a service type chosen. Drives the enabled/disabled
/// state of the "اختيار المختبر" bottom CTA.

final class CanContinueFromUploadProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True once both screen-1 disable-conditions are satisfied: at least one
  /// image attached AND a service type chosen. Drives the enabled/disabled
  /// state of the "اختيار المختبر" bottom CTA.
  CanContinueFromUploadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canContinueFromUploadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canContinueFromUploadHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canContinueFromUpload(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canContinueFromUploadHash() =>
    r'1de5ccf5f2e873f733ef72e0669d95a9bed23a2c';
