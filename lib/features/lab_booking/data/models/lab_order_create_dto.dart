import 'package:med_super/features/lab_booking/domain/entities/lab_order_create_result.dart';

/// Parses `POST /v1/lab-orders`'s response — camelCase, same reasoning as
/// `PharmacyOrderCreateDto` (plain object literal returned by the use-case,
/// no class-transformer casing rewrite in this backend).
class LabOrderCreateDto {
  const LabOrderCreateDto({required this.labOrderId, required this.status});

  factory LabOrderCreateDto.fromJson(Map<String, dynamic> json) {
    return LabOrderCreateDto(
      labOrderId: json['labOrderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String labOrderId;
  final String status;

  LabOrderCreateResult toEntity() =>
      LabOrderCreateResult(labOrderId: labOrderId, status: status);
}
