// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_schedule_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The next 4 selectable days (today included), matching the Figma design.
/// No backend design exists yet for real per-lab availability, so this is
/// generated client-side rather than inventing a network shape for it.

@ProviderFor(labAvailableDays)
final labAvailableDaysProvider = LabAvailableDaysProvider._();

/// The next 4 selectable days (today included), matching the Figma design.
/// No backend design exists yet for real per-lab availability, so this is
/// generated client-side rather than inventing a network shape for it.

final class LabAvailableDaysProvider
    extends $FunctionalProvider<List<DateTime>, List<DateTime>, List<DateTime>>
    with $Provider<List<DateTime>> {
  /// The next 4 selectable days (today included), matching the Figma design.
  /// No backend design exists yet for real per-lab availability, so this is
  /// generated client-side rather than inventing a network shape for it.
  LabAvailableDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labAvailableDaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labAvailableDaysHash();

  @$internal
  @override
  $ProviderElement<List<DateTime>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<DateTime> create(Ref ref) {
    return labAvailableDays(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DateTime> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DateTime>>(value),
    );
  }
}

String _$labAvailableDaysHash() => r'fdd8c7a526c1199576c2a1e6d9ad8cede8d26b20';

/// Fixed morning/evening time-slot templates, keyed by period.
/// One evening slot ('16:30') is marked unavailable to match the design's
/// dimmed slot and exercise the "not every slot is bookable" UI state.

@ProviderFor(labTimeSlotsByPeriod)
final labTimeSlotsByPeriodProvider = LabTimeSlotsByPeriodProvider._();

/// Fixed morning/evening time-slot templates, keyed by period.
/// One evening slot ('16:30') is marked unavailable to match the design's
/// dimmed slot and exercise the "not every slot is bookable" UI state.

final class LabTimeSlotsByPeriodProvider
    extends
        $FunctionalProvider<
          Map<String, List<LabTimeSlot>>,
          Map<String, List<LabTimeSlot>>,
          Map<String, List<LabTimeSlot>>
        >
    with $Provider<Map<String, List<LabTimeSlot>>> {
  /// Fixed morning/evening time-slot templates, keyed by period.
  /// One evening slot ('16:30') is marked unavailable to match the design's
  /// dimmed slot and exercise the "not every slot is bookable" UI state.
  LabTimeSlotsByPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labTimeSlotsByPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labTimeSlotsByPeriodHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<LabTimeSlot>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<LabTimeSlot>> create(Ref ref) {
    return labTimeSlotsByPeriod(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<LabTimeSlot>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<LabTimeSlot>>>(
        value,
      ),
    );
  }
}

String _$labTimeSlotsByPeriodHash() =>
    r'9e6ce09cf2c55c0fb3d484f9b02ca98c6c3517a8';

/// Selected day for the schedule step — defaults to the last (furthest)
/// available day, matching the Figma default selection.

@ProviderFor(SelectedScheduleDay)
final selectedScheduleDayProvider = SelectedScheduleDayProvider._();

/// Selected day for the schedule step — defaults to the last (furthest)
/// available day, matching the Figma default selection.
final class SelectedScheduleDayProvider
    extends $NotifierProvider<SelectedScheduleDay, DateTime> {
  /// Selected day for the schedule step — defaults to the last (furthest)
  /// available day, matching the Figma default selection.
  SelectedScheduleDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedScheduleDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedScheduleDayHash();

  @$internal
  @override
  SelectedScheduleDay create() => SelectedScheduleDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedScheduleDayHash() =>
    r'c18b4a6cebbb514e2cf89e5b9099b64cf27c49dc';

/// Selected day for the schedule step — defaults to the last (furthest)
/// available day, matching the Figma default selection.

abstract class _$SelectedScheduleDay extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Selected time slot — required before confirming; null until the user
/// (or the design's own pre-selected default) picks one.

@ProviderFor(SelectedTimeSlot)
final selectedTimeSlotProvider = SelectedTimeSlotProvider._();

/// Selected time slot — required before confirming; null until the user
/// (or the design's own pre-selected default) picks one.
final class SelectedTimeSlotProvider
    extends $NotifierProvider<SelectedTimeSlot, String?> {
  /// Selected time slot — required before confirming; null until the user
  /// (or the design's own pre-selected default) picks one.
  SelectedTimeSlotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTimeSlotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTimeSlotHash();

  @$internal
  @override
  SelectedTimeSlot create() => SelectedTimeSlot();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedTimeSlotHash() => r'338effb2b9caa84c757ed952a18647810a4f3cbd';

/// Selected time slot — required before confirming; null until the user
/// (or the design's own pre-selected default) picks one.

abstract class _$SelectedTimeSlot extends $Notifier<String?> {
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

/// Selected payment method — online payment pre-selected, matching Figma.

@ProviderFor(SelectedPaymentMethod)
final selectedPaymentMethodProvider = SelectedPaymentMethodProvider._();

/// Selected payment method — online payment pre-selected, matching Figma.
final class SelectedPaymentMethodProvider
    extends $NotifierProvider<SelectedPaymentMethod, LabPaymentMethod> {
  /// Selected payment method — online payment pre-selected, matching Figma.
  SelectedPaymentMethodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPaymentMethodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPaymentMethodHash();

  @$internal
  @override
  SelectedPaymentMethod create() => SelectedPaymentMethod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabPaymentMethod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabPaymentMethod>(value),
    );
  }
}

String _$selectedPaymentMethodHash() =>
    r'06110e0b3cfbb1d746ec1bd1b2581ddf2c892db0';

/// Selected payment method — online payment pre-selected, matching Figma.

abstract class _$SelectedPaymentMethod extends $Notifier<LabPaymentMethod> {
  LabPaymentMethod build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LabPaymentMethod, LabPaymentMethod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LabPaymentMethod, LabPaymentMethod>,
              LabPaymentMethod,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Home-collection address, edited from the review step's schedule/address
/// edit modal. Only meaningful when the service type is home collection;
/// seeded with a placeholder since no saved-address feature exists yet.

@ProviderFor(SelectedLabAddress)
final selectedLabAddressProvider = SelectedLabAddressProvider._();

/// Home-collection address, edited from the review step's schedule/address
/// edit modal. Only meaningful when the service type is home collection;
/// seeded with a placeholder since no saved-address feature exists yet.
final class SelectedLabAddressProvider
    extends $NotifierProvider<SelectedLabAddress, String> {
  /// Home-collection address, edited from the review step's schedule/address
  /// edit modal. Only meaningful when the service type is home collection;
  /// seeded with a placeholder since no saved-address feature exists yet.
  SelectedLabAddressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedLabAddressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedLabAddressHash();

  @$internal
  @override
  SelectedLabAddress create() => SelectedLabAddress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedLabAddressHash() =>
    r'8db27c291b07450666a2516648d5b461f1b5c3bd';

/// Home-collection address, edited from the review step's schedule/address
/// edit modal. Only meaningful when the service type is home collection;
/// seeded with a placeholder since no saved-address feature exists yet.

abstract class _$SelectedLabAddress extends $Notifier<String> {
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
