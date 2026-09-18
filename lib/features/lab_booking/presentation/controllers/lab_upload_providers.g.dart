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
///
/// Reuses `pharmacy_booking`'s `PrescriptionImage` value object rather than
/// keeping a structurally-identical `LabRequestImage` of its own — both
/// features upload through the same real endpoint
/// (`POST /v1/prescriptions/upload`, `PrescriptionRemoteDatasource`), so this
/// is the same picked-image shape either way.

@ProviderFor(UploadedLabRequestImages)
final uploadedLabRequestImagesProvider = UploadedLabRequestImagesProvider._();

/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).
///
/// Reuses `pharmacy_booking`'s `PrescriptionImage` value object rather than
/// keeping a structurally-identical `LabRequestImage` of its own — both
/// features upload through the same real endpoint
/// (`POST /v1/prescriptions/upload`, `PrescriptionRemoteDatasource`), so this
/// is the same picked-image shape either way.
final class UploadedLabRequestImagesProvider
    extends
        $NotifierProvider<UploadedLabRequestImages, List<PrescriptionImage>> {
  /// Images the patient has attached to the lab request on screen 1
  /// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
  /// hard requirement before the "اختيار المختبر" CTA activates (see
  /// [canContinueFromUploadProvider]).
  ///
  /// Reuses `pharmacy_booking`'s `PrescriptionImage` value object rather than
  /// keeping a structurally-identical `LabRequestImage` of its own — both
  /// features upload through the same real endpoint
  /// (`POST /v1/prescriptions/upload`, `PrescriptionRemoteDatasource`), so this
  /// is the same picked-image shape either way.
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
  Override overrideWithValue(List<PrescriptionImage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PrescriptionImage>>(value),
    );
  }
}

String _$uploadedLabRequestImagesHash() =>
    r'1b9c3dc97cc641932d46ec516659e0816a0ac1fe';

/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).
///
/// Reuses `pharmacy_booking`'s `PrescriptionImage` value object rather than
/// keeping a structurally-identical `LabRequestImage` of its own — both
/// features upload through the same real endpoint
/// (`POST /v1/prescriptions/upload`, `PrescriptionRemoteDatasource`), so this
/// is the same picked-image shape either way.

abstract class _$UploadedLabRequestImages
    extends $Notifier<List<PrescriptionImage>> {
  List<PrescriptionImage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<PrescriptionImage>, List<PrescriptionImage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PrescriptionImage>, List<PrescriptionImage>>,
              List<PrescriptionImage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the continue CTA stays disabled until the patient
/// makes an explicit choice.

@ProviderFor(SelectedLabServiceType)
final selectedLabServiceTypeProvider = SelectedLabServiceTypeProvider._();

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the continue CTA stays disabled until the patient
/// makes an explicit choice.
final class SelectedLabServiceTypeProvider
    extends $NotifierProvider<SelectedLabServiceType, LabServiceType?> {
  /// Which service type ("نوع الخدمة") the patient picked. Deliberately has
  /// no default value — the continue CTA stays disabled until the patient
  /// makes an explicit choice.
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
    r'3b1fb0b5bfc4accfa1b87a70a97cca9dcbfbdfb2';

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the continue CTA stays disabled until the patient
/// makes an explicit choice.

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
