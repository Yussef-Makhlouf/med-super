import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';

class PharmacyOrderDetailDto {
  const PharmacyOrderDetailDto({
    required this.id,
    required this.status,
    required this.fulfillmentType,
    required this.createdAt,
    required this.updatedAt,
    required this.doctorName,
    required this.quote,
    required this.patientNote,
    required this.staffNote,
    required this.prescriptionImages,
    required this.rejection,
  });

  factory PharmacyOrderDetailDto.fromJson(Map<String, dynamic> json) {
    final prescription = json['prescription'] as Map<String, dynamic>?;
    final quoteJson = json['quote'] as Map<String, dynamic>?;
    final rejectionJson = json['rejection'] as Map<String, dynamic>?;
    final imagesJson = prescription?['images'] as List<dynamic>? ?? const [];
    return PharmacyOrderDetailDto(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      fulfillmentType: json['fulfillmentType'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      doctorName: prescription?['doctorName'] as String?,
      quote: quoteJson == null
          ? null
          : PharmacyOrderQuote(
              totalPrice: quoteJson['totalPrice'] as String? ?? '',
              currency: quoteJson['currency'] as String? ?? '',
              estimatedReadyMinutes:
                  quoteJson['estimatedReadyMinutes'] as int?,
              note: quoteJson['note'] as String?,
              quotedAt: quoteJson['quotedAt'] as String? ?? '',
            ),
      patientNote: json['patientNote'] as String?,
      staffNote: json['staffNote'] as String?,
      prescriptionImages: imagesJson
          .whereType<Map<String, dynamic>>()
          .map(
            (image) => PharmacyOrderPrescriptionImage(
              id: image['id'] as String? ?? '',
              fileUrl: image['fileUrl'] as String? ?? '',
              qualityCheckStatus: image['qualityCheckStatus'] as String? ?? '',
            ),
          )
          .toList(),
      rejection: rejectionJson == null
          ? null
          : PharmacyOrderRejection(
              reason: rejectionJson['reason'] as String? ?? '',
              note: rejectionJson['note'] as String?,
              at: rejectionJson['at'] as String? ?? '',
            ),
    );
  }

  final String id;
  final String status;
  final String fulfillmentType;
  final String createdAt;
  final String updatedAt;
  final String? doctorName;
  final PharmacyOrderQuote? quote;
  final String? patientNote;
  final String? staffNote;
  final List<PharmacyOrderPrescriptionImage> prescriptionImages;
  final PharmacyOrderRejection? rejection;

  PharmacyOrderDetail toEntity() => PharmacyOrderDetail(
    id: id,
    status: status,
    fulfillmentType: fulfillmentType,
    createdAt: createdAt,
    updatedAt: updatedAt,
    pharmacyName: null,
    doctorName: doctorName,
    quote: quote,
    patientNote: patientNote,
    staffNote: staffNote,
    prescriptionImages: prescriptionImages,
    rejection: rejection,
  );
}
