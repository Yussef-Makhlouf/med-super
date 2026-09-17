import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/models/lab_order_create_dto.dart';
import 'package:med_super/features/lab_booking/data/models/lab_order_detail_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_create_result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';

class LabOrderRemoteDatasource {
  LabOrderRemoteDatasource(this._dio);

  final Dio _dio;

  /// `POST /v1/lab-orders`, `PATIENT`-role (`clinic-reservations`
  /// `CreateLabOrderUseCase`). Either [testCodes] or [prescriptionId] must be
  /// given — `med-super` only ever exercises the [prescriptionId] path today
  /// (the direct catalog-selection path has no picker UI yet: `test_catalog`
  /// is unseeded and has no read endpoint, see `lab_booking/STATUS.md`).
  Future<LabOrderCreateResult> create({
    required String labBranchId,
    required String collectionType,
    String? prescriptionId,
    List<String>? testCodes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.labOrders,
      data: {
        'labBranchId': labBranchId,
        'collectionType': collectionType,
        if (prescriptionId != null) 'prescriptionId': prescriptionId,
        if (testCodes != null && testCodes.isNotEmpty) 'testCodes': testCodes,
      },
    );
    return LabOrderCreateDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  /// `GET /v1/lab-orders` — the caller's own orders (patient-scoped
  /// server-side, no query param needed), newest first (backend default
  /// sort). Not paginated here yet — only the first page's `orders` is read,
  /// same tradeoff `PharmacyOrderRemoteDatasource.list` already makes.
  Future<List<LabOrderDetail>> list() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.labOrders);
    final orders = response.data?['orders'] as List<dynamic>? ?? const [];
    return orders
        .whereType<Map<String, dynamic>>()
        .map(LabOrderDetailDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList();
  }

  Future<LabOrderDetail> getDetail(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.labOrders}/$orderId',
    );
    return LabOrderDetailDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}
