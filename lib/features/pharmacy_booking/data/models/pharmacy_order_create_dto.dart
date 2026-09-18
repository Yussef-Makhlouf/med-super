import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_create_result.dart';

/// Parses `POST /v1/pharmacy-orders`'s response — camelCase, same reasoning
/// as `PrescriptionUploadDto` (plain object literal returned by the
/// use-case, no class-transformer casing rewrite in this backend).
class PharmacyOrderCreateDto {
  const PharmacyOrderCreateDto({
    required this.pharmacyOrderId,
    required this.status,
    required this.broadcastedBranchIds,
  });

  factory PharmacyOrderCreateDto.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderCreateDto(
      pharmacyOrderId: json['pharmacyOrderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      broadcastedBranchIds:
          (json['broadcastedBranchIds'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
    );
  }

  final String pharmacyOrderId;
  final String status;
  final List<String> broadcastedBranchIds;

  PharmacyOrderCreateResult toEntity() => PharmacyOrderCreateResult(
    pharmacyOrderId: pharmacyOrderId,
    status: status,
    broadcastedBranchIds: broadcastedBranchIds,
  );
}
