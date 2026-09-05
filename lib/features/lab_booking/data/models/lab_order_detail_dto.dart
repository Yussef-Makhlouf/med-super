import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';

/// Parses `GET /v1/lab-orders`/`GET /v1/lab-orders/:id`'s per-order shape
/// (`clinic-reservations` `LabOrderDetail`, `lab-order-detail.mapper.ts`) —
/// only the fields the patient-facing tracking screen surfaces (see
/// `LabOrderDetail`'s own doc comment for what's deliberately left out).
class LabOrderDetailDto {
  const LabOrderDetailDto({
    required this.id,
    required this.status,
    required this.collectionType,
    required this.createdAt,
    required this.updatedAt,
    required this.branchId,
    required this.items,
    required this.quote,
    required this.bookingCode,
    required this.rejection,
    required this.recollectionRequired,
  });

  factory LabOrderDetailDto.fromJson(Map<String, dynamic> json) {
    final quoteJson = json['quote'] as Map<String, dynamic>?;
    final rejectionJson = json['rejection'] as Map<String, dynamic>?;
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return LabOrderDetailDto(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      collectionType: json['collectionType'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => LabOrderItem(
              id: item['id'] as String? ?? '',
              catalogCode: item['catalogCode'] as String? ?? '',
              displayName: item['displayName'] as String? ?? '',
              unitPrice: item['unitPrice'] as String?,
              resultState: item['resultState'] as String? ?? '',
            ),
          )
          .toList(),
      quote: quoteJson == null
          ? null
          : LabOrderQuote(
              totalPrice: quoteJson['totalPrice'] as String? ?? '',
              currency: quoteJson['currency'] as String? ?? '',
              appointmentAt: quoteJson['appointmentAt'] as String? ?? '',
              prepInstructions: quoteJson['prepInstructions'] as String? ?? '',
              quotedAt: quoteJson['quotedAt'] as String? ?? '',
            ),
      bookingCode: json['bookingCode'] as String?,
      rejection: rejectionJson == null
          ? null
          : LabOrderRejection(
              reason: rejectionJson['reason'] as String? ?? '',
              note: rejectionJson['note'] as String?,
              at: rejectionJson['at'] as String? ?? '',
            ),
      recollectionRequired: json['recollectionRequired'] as bool? ?? false,
    );
  }

  final String id;
  final String status;
  final String collectionType;
  final String createdAt;
  final String updatedAt;
  final String branchId;
  final List<LabOrderItem> items;
  final LabOrderQuote? quote;
  final String? bookingCode;
  final LabOrderRejection? rejection;
  final bool recollectionRequired;

  LabOrderDetail toEntity() => LabOrderDetail(
    id: id,
    status: status,
    collectionType: collectionType,
    createdAt: createdAt,
    updatedAt: updatedAt,
    branchId: branchId,
    items: items,
    quote: quote,
    bookingCode: bookingCode,
    rejection: rejection,
    recollectionRequired: recollectionRequired,
  );
}
