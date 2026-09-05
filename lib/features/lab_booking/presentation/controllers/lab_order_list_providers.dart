import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_order_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';

final labOrderRemoteDatasourceProvider = Provider<LabOrderRemoteDatasource>(
  (ref) => LabOrderRemoteDatasource(ref.watch(dioProvider)),
);

/// `GET /v1/lab-orders` — the patient's own lab orders, newest first
/// (backend default sort).
final labOrdersProvider = FutureProvider<List<LabOrderDetail>>((ref) {
  return ref.watch(labOrderRemoteDatasourceProvider).list();
});

/// `GET /v1/lab-orders/:id` — a single order's detail, including its quote
/// once staff has priced it and its booking code once confirmed.
final labOrderDetailProvider = FutureProvider.family<LabOrderDetail, String>((
  ref,
  orderId,
) {
  return ref.watch(labOrderRemoteDatasourceProvider).getDetail(orderId);
});
