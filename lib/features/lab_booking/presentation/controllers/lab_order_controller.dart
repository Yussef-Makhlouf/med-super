import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_create_result.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_list_providers.dart';

/// Drives `POST /v1/lab-orders` from the review screen's confirm button.
/// Everything this call needs (the already-uploaded prescription, the
/// chosen collection type and lab branch) was decided on earlier screens —
/// this controller only fires the request and tracks its result. Mirrors
/// `pharmacy_booking`'s `PharmacyOrderController`, simpler: `labBranchId` is
/// always required (no location-based broadcast fallback — a lab order is
/// always assigned to exactly one, caller-chosen branch), so there is no
/// device-location precondition to guard here.
class LabOrderController extends Notifier<AsyncValue<LabOrderCreateResult?>> {
  @override
  AsyncValue<LabOrderCreateResult?> build() => const AsyncData(null);

  Future<void> submit({
    required String labBranchId,
    required String collectionType,
    String? prescriptionId,
    List<String>? testCodes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(labOrderRemoteDatasourceProvider)
          .create(
            labBranchId: labBranchId,
            collectionType: collectionType,
            prescriptionId: prescriptionId,
            testCodes: testCodes,
          ),
    );
    // Without this, the orders-tab list (`labOrdersProvider`) is a separate
    // cached fetch and keeps showing whatever it last loaded — a brand-new
    // order wouldn't appear there until an unrelated refetch happened to
    // occur, same staleness class `PharmacyOrderController.submit` guards
    // against.
    if (!state.hasError) {
      ref.invalidate(labOrdersProvider);
    }
  }
}

final labOrderControllerProvider =
    NotifierProvider<LabOrderController, AsyncValue<LabOrderCreateResult?>>(
      LabOrderController.new,
    );
