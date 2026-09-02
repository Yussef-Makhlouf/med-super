import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';

/// Parses `POST /v1/prescriptions/upload`'s response — the use-case returns
/// a plain `{ prescriptionId, status }` object literal (no class-transformer
/// casing rewrite anywhere in this backend), so the JSON keys are camelCase
/// as written, not `snake_case`.
class PrescriptionUploadDto {
  const PrescriptionUploadDto({required this.prescriptionId, required this.status});

  factory PrescriptionUploadDto.fromJson(Map<String, dynamic> json) {
    return PrescriptionUploadDto(
      prescriptionId: json['prescriptionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String prescriptionId;
  final String status;

  PrescriptionUploadResult toEntity() => PrescriptionUploadResult(
    prescriptionId: prescriptionId,
    status: status,
  );
}
