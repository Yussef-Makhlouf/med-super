import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/models/lab_order_detail_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_order_detail_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/provider_dashboard/data/models/provider_clinical_request_dto.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provider_clinical_request.dart';

class ProviderClinicalRequestsRemoteDatasource {
  ProviderClinicalRequestsRemoteDatasource(this._dio);
  final Dio _dio;

  Future<ProviderPrescriptionResult> createPrescription({
    required String patientId,
    required List<ProviderPrescriptionItem> items,
    String? appointmentId,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerPrescriptions,
      data: {
        'patientId': patientId,
        'items': items.map(_prescriptionItemJson).toList(growable: false),
        if (appointmentId != null) 'appointmentId': appointmentId,
        ...?((notes != null && notes.trim().isNotEmpty)
            ? {'notes': notes.trim()}
            : null),
      },
    );
    return ProviderPrescriptionResultDto.fromJson(
      response.data ?? {},
    ).toEntity();
  }

  /// Calls the authoritative atomic endpoint.  The server checks every
  /// patient scope and rejects duplicate patients before any request is made.
  Future<ProviderPrescriptionBatchResult> createPrescriptionBatch(
    List<ProviderPrescriptionRequest> requests,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerPrescriptions}/batch',
      data: {
        'requests': requests
            .map(
              (request) => {
                'patientId': request.patientId,
                'items': request.items
                    .map(_prescriptionItemJson)
                    .toList(growable: false),
                if (request.appointmentId != null)
                  'appointmentId': request.appointmentId,
                if (request.notes?.trim().isNotEmpty == true)
                  'notes': request.notes!.trim(),
              },
            )
            .toList(growable: false),
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final rows = data['results'] as List<dynamic>? ?? const [];
    return ProviderPrescriptionBatchResult(
      batchId: data['batchId'] as String? ?? '',
      results: rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            return ProviderPrescriptionBatchItemResult(
              patientId: row['patientId'] as String? ?? '',
              prescriptionId: row['prescriptionId'] as String? ?? '',
              status: row['status'] as String? ?? 'UNKNOWN',
            );
          })
          .toList(growable: false),
    );
  }

  Future<List<ProviderPrescription>> listPrescriptions() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerPrescriptions,
      queryParameters: const {'limit': 50},
    );
    final rows = response.data?['prescriptions'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ProviderPrescriptionDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<ProviderPrescription> getPrescription(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.providerPrescriptions}/$id',
    );
    return ProviderPrescriptionDto.fromJson(response.data ?? {}).toEntity();
  }

  Future<void> decidePrescription({
    required String id,
    required int version,
    required bool approve,
    String? reason,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerPrescriptions}/$id/${approve ? 'approve' : 'reject'}',
      data: {
        'expectedVersion': version,
        if (!approve) 'reason': reason?.trim() ?? '',
      },
    );
  }

  Future<List<ProviderLabTest>> searchLabCatalog(String search) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.labOrderCatalog,
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    final rows = response.data?['items'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ProviderLabTestDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<ProviderLabRequestResult> createLabOrder({
    required String patientId,
    required String labBranchId,
    required String collectionType,
    required List<String> testCodes,
    String? appointmentId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.labOrders}/provider',
      data: {
        'patientId': patientId,
        'labBranchId': labBranchId,
        'collectionType': collectionType,
        'testCodes': testCodes,
        if (appointmentId != null) 'appointmentId': appointmentId,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return ProviderLabRequestResult(
      labOrderId: data['labOrderId'] as String? ?? data['id'] as String? ?? '',
      status: data['status'] as String? ?? 'REQUESTED',
    );
  }

  Future<ProviderLabBatchResult> createLabOrderBatch(
    List<ProviderLabRequest> requests,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.labOrders}/provider/batch',
      data: {
        'requests': requests
            .map(
              (request) => {
                'patientId': request.patientId,
                'labBranchId': request.labBranchId,
                'collectionType': request.collectionType,
                if (request.testCodes.isNotEmpty)
                  'testCodes': request.testCodes,
                if (request.prescriptionId != null)
                  'prescriptionId': request.prescriptionId,
                if (request.appointmentId != null)
                  'appointmentId': request.appointmentId,
              },
            )
            .toList(growable: false),
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final rows = data['results'] as List<dynamic>? ?? const [];
    return ProviderLabBatchResult(
      batchId: data['batchId'] as String? ?? '',
      results: rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            return ProviderLabBatchItemResult(
              patientId: row['patientId'] as String? ?? '',
              labOrderId: row['labOrderId'] as String? ?? '',
              status: row['status'] as String? ?? 'UNKNOWN',
            );
          })
          .toList(growable: false),
    );
  }

  Future<List<LabOrderDetail>> listLabOrders() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.labOrders);
    final rows = response.data?['orders'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(LabOrderDetailDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<List<PharmacyOrderDetail>> listPharmacyOrders() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.pharmacyOrders,
    );
    final rows = response.data?['orders'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PharmacyOrderDetailDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<ProviderPharmacyRequestResult> createPharmacyOrder({
    required String patientId,
    required String prescriptionId,
    required String fulfillmentType,
    String? pharmacyBranchId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.pharmacyOrders}/provider',
      data: {
        'patientId': patientId,
        'prescriptionId': prescriptionId,
        'fulfillmentType': fulfillmentType,
        if (pharmacyBranchId != null) 'pharmacyBranchId': pharmacyBranchId,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return ProviderPharmacyRequestResult(
      pharmacyOrderId:
          data['pharmacyOrderId'] as String? ?? data['id'] as String? ?? '',
      status: data['status'] as String? ?? 'RECEIVED',
    );
  }

  static Map<String, dynamic> _prescriptionItemJson(
    ProviderPrescriptionItem item,
  ) => {
    'drugNameFreeText': item.drugName,
    'quantity': item.quantity,
    if (item.dose?.trim().isNotEmpty == true) 'dose': item.dose!.trim(),
    if (item.frequency?.trim().isNotEmpty == true)
      'frequency': item.frequency!.trim(),
    if (item.durationDays != null) 'durationDays': item.durationDays,
  };
}
