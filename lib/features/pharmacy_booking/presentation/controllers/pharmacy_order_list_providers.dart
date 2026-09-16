import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirm_receipt_result.dart';
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

/// Drives `POST /v1/pharmacy-orders/:id/confirm-receipt` from the
/// order-detail screen's "تأكيد الاستلام" button (shown only while a
/// home-delivery order is `OUT_FOR_DELIVERY`).
class PharmacyOrderConfirmReceiptController
    extends Notifier<AsyncValue<PharmacyOrderConfirmReceiptResult?>> {
  @override
  AsyncValue<PharmacyOrderConfirmReceiptResult?> build() =>
      const AsyncData(null);

  Future<void> confirmReceipt(String orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(pharmacyOrderRemoteDatasourceProvider)
          .confirmReceipt(orderId),
    );
  }
}

final pharmacyOrderConfirmReceiptControllerProvider = NotifierProvider<
  PharmacyOrderConfirmReceiptController,
  AsyncValue<PharmacyOrderConfirmReceiptResult?>
>(PharmacyOrderConfirmReceiptController.new);
