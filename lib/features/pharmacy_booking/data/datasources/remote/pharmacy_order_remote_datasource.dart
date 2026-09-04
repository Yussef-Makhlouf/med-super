import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_order_approve_dto.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_order_confirm_receipt_dto.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_order_create_dto.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_order_detail_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_approve_result.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirm_receipt_result.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_create_result.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';

class PharmacyOrderRemoteDatasource {
  PharmacyOrderRemoteDatasource(this._dio);

  final Dio _dio;

  /// `lat`/`lng` are only required by the backend when [pharmacyBranchId] is
  /// omitted (`clinic-reservations` File 12 Part 46) — a chosen branch is
  /// broadcast to directly and never needs the caller's location.
  Future<PharmacyOrderCreateResult> create({
    required String prescriptionId,
    required String fulfillmentType,
    double? lat,
    double? lng,
    String? pharmacyBranchId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.pharmacyOrders,
      data: {
        'prescriptionId': prescriptionId,
        'fulfillmentType': fulfillmentType,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (pharmacyBranchId != null) 'pharmacyBranchId': pharmacyBranchId,
      },
    );
    return PharmacyOrderCreateDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  /// `GET /v1/pharmacy-orders` — the caller's own orders (patient-scoped
  /// server-side, no query param needed). Not paginated here yet: only the
  /// first page's `items` is read, matching this screen's expected order
  /// count for now.
  Future<List<PharmacyOrderDetail>> list() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.pharmacyOrders,
    );
    final orders = response.data?['orders'] as List<dynamic>? ?? const [];
    return orders
        .whereType<Map<String, dynamic>>()
        .map(PharmacyOrderDetailDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList();
  }

  Future<PharmacyOrderDetail> getDetail(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.pharmacyOrders}/$orderId',
    );
    return PharmacyOrderDetailDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  Future<PharmacyOrderApproveResult> approve(String orderId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.pharmacyOrders}/$orderId/approve',
    );
    return PharmacyOrderApproveDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  /// `POST /v1/pharmacy-orders/:id/confirm-receipt` — patient-triggered,
  /// `OUT_FOR_DELIVERY -> FULFILLED` (`clinic-reservations`
  /// `ConfirmPharmacyOrderReceiptUseCase`). Only valid while the order is out
  /// for delivery; a pickup order is closed by pharmacy staff instead.
  Future<PharmacyOrderConfirmReceiptResult> confirmReceipt(
    String orderId,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.pharmacyOrders}/$orderId/confirm-receipt',
    );
    return PharmacyOrderConfirmReceiptDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}
