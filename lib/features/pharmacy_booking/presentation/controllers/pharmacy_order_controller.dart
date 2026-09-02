import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/pharmacy_order_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_create_result.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';

/// Thrown by [PharmacyOrderController.submit] when the device's location
/// can't be read AND no specific branch was chosen — `POST
/// /v1/pharmacy-orders`'s `lat`/`lng` are only required in that case
/// (`clinic-reservations` File 12 Part 46): a chosen branch is broadcast to
/// directly and never needs the caller's GPS to resolve nearest branches,
/// so forcing a location read on every submit was an unnecessary blocker.
class PharmacyOrderLocationUnavailableException implements Exception {
  const PharmacyOrderLocationUnavailableException();
}

final pharmacyOrderRemoteDatasourceProvider = Provider<PharmacyOrderRemoteDatasource>(
  (ref) => PharmacyOrderRemoteDatasource(ref.watch(dioProvider)),
);

/// Drives `POST /v1/pharmacy-orders` from the order-review screen's confirm
/// button. Everything this call needs (the already-uploaded prescription,
/// the chosen delivery method and pharmacy branch) was decided on earlier
/// screens — this controller only fires the request and tracks its result.
class PharmacyOrderController extends Notifier<AsyncValue<PharmacyOrderCreateResult?>> {
  @override
  AsyncValue<PharmacyOrderCreateResult?> build() => const AsyncData(null);

  Future<void> submit({
    required String prescriptionId,
    required String fulfillmentType,
    String? pharmacyBranchId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final position = await ref
          .read(pharmacyLocationServiceProvider)
          .getCurrentPosition();
      if (position == null && pharmacyBranchId == null) {
        throw const PharmacyOrderLocationUnavailableException();
      }
      return ref
          .read(pharmacyOrderRemoteDatasourceProvider)
          .create(
            prescriptionId: prescriptionId,
            fulfillmentType: fulfillmentType,
            lat: position?.latitude,
            lng: position?.longitude,
            pharmacyBranchId: pharmacyBranchId,
          );
    });
  }
}

final pharmacyOrderControllerProvider =
    NotifierProvider<PharmacyOrderController, AsyncValue<PharmacyOrderCreateResult?>>(
      PharmacyOrderController.new,
    );
