import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';

/// Real Phase 3 contract: `GET /v1/doctors/{doctorId}/slots?clinicBranchId=&from=&to=`
/// (clinic-reservations/src/modules/scheduling-appointments/api/doctor-slots.controller.ts).
/// Response: `{ slots: [{ slotId, startAt, endAt, status: 'OPEN' }] }` — the
/// backend only ever returns `OPEN` slots from this endpoint, camelCase
/// (unlike the doctor-detail endpoint, which currently leaks raw snake_case
/// Prisma field names — see med-super/docs/backend_frontend_parity_matrix.md).
class DoctorSlotsRemoteDatasource {
  DoctorSlotsRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<DoctorSlot>> getDoctorSlots({
    required String doctorId,
    required String clinicBranchId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.doctors}/$doctorId/slots',
      queryParameters: {
        'clinicBranchId': clinicBranchId,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final slots = (data['slots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (s) => DoctorSlot(
            slotId: s['slotId'] as String,
            startAtUtc: DateTime.parse(s['startAt'] as String).toUtc(),
            endAtUtc: DateTime.parse(s['endAt'] as String).toUtc(),
          ),
        )
        .toList();
    return slots;
  }
}
