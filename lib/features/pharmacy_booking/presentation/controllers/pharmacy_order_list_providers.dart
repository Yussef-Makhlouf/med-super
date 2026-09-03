import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_approve_result.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_controller.dart';

/// `GET /v1/pharmacy-orders` — the patient's own pharmacy orders, newest
/// first (backend default sort).
final pharmacyOrdersProvider = FutureProvider<List<PharmacyOrderDetail>>((
  ref,
) {
  return ref.watch(pharmacyOrderRemoteDatasourceProvider).list();
});

/// `GET /v1/pharmacy-orders/:id` — a single order's detail, including its
/// quote once a branch has priced it.
final pharmacyOrderDetailProvider = FutureProvider.family<
  PharmacyOrderDetail,
  String
>((ref, orderId) {
  return ref.watch(pharmacyOrderRemoteDatasourceProvider).getDetail(orderId);
});

/// Drives `POST /v1/pharmacy-orders/:id/approve` from the order-detail
/// screen's "وافق وادفع" button.
class PharmacyOrderApproveController
    extends Notifier<AsyncValue<PharmacyOrderApproveResult?>> {
  @override
  AsyncValue<PharmacyOrderApproveResult?> build() => const AsyncData(null);

  Future<void> approve(String orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(pharmacyOrderRemoteDatasourceProvider).approve(orderId),
    );
  }
}

final pharmacyOrderApproveControllerProvider = NotifierProvider<
  PharmacyOrderApproveController,
  AsyncValue<PharmacyOrderApproveResult?>
>(PharmacyOrderApproveController.new);
