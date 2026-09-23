import '../../domain/entities/provider_clinical_request.dart';

class ProviderPrescriptionDto {
  const ProviderPrescriptionDto(this.value);
  final Map<String, dynamic> value;

  factory ProviderPrescriptionDto.fromJson(Map<String, dynamic> json) =>
      ProviderPrescriptionDto(json);

  ProviderPrescription toEntity() {
    final items = value['items'] as List<dynamic>? ?? const [];
    return ProviderPrescription(
      id: value['id'] as String? ?? value['prescriptionId'] as String? ?? '',
      patientId: value['patientId'] as String? ?? '',
      status: value['status'] as String? ?? 'UNKNOWN',
      version: value['version'] as int? ?? 1,
      createdAt: DateTime.tryParse(value['createdAt'] as String? ?? ''),
      appointmentId: value['appointmentId'] as String?,
      notes: value['notes'] as String?,
      source: value['source'] as String?,
      createdByRole: value['createdByRole'] as String?,
      rejectionReason: value['rejectionReason'] as String?,
      items: items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ProviderPrescriptionItem(
              drugName:
                  item['drugName'] as String? ??
                  item['drugNameFreeText'] as String? ??
                  '',
              dose: item['dose'] as String?,
              frequency: item['frequency'] as String?,
              durationDays: item['durationDays'] as int?,
              quantity: item['quantity'] as int? ?? 1,
            ),
          )
          .toList(growable: false),
    );
  }
}

class ProviderPrescriptionResultDto {
  const ProviderPrescriptionResultDto({required this.id, required this.status});
  final String id;
  final String status;
  factory ProviderPrescriptionResultDto.fromJson(Map<String, dynamic> json) =>
      ProviderPrescriptionResultDto(
        id: json['prescriptionId'] as String? ?? json['id'] as String? ?? '',
        status: json['status'] as String? ?? 'UNKNOWN',
      );
  ProviderPrescriptionResult toEntity() =>
      ProviderPrescriptionResult(prescriptionId: id, status: status);
}

class ProviderLabTestDto {
  const ProviderLabTestDto({required this.code, required this.displayName});
  final String code;
  final String displayName;
  factory ProviderLabTestDto.fromJson(Map<String, dynamic> json) =>
      ProviderLabTestDto(
        code: json['code'] as String? ?? '',
        displayName:
            json['displayName'] as String? ?? json['code'] as String? ?? '',
      );
  ProviderLabTest toEntity() =>
      ProviderLabTest(code: code, displayName: displayName);
}
