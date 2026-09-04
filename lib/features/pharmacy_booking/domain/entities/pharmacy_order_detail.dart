/// A quote the pharmacy branch submitted for the order — present once the
/// branch has accepted and priced it, `null` while still `RECEIVED`.
class PharmacyOrderQuote {
  const PharmacyOrderQuote({
    required this.totalPrice,
    required this.currency,
    required this.estimatedReadyMinutes,
    required this.note,
    required this.quotedAt,
  });

  final String totalPrice;
  final String currency;
  final int? estimatedReadyMinutes;
  final String? note;
  final String quotedAt;
}

/// Why the branch rejected the order — present only once `status` is
/// `REJECTED`.
class PharmacyOrderRejection {
  const PharmacyOrderRejection({
    required this.reason,
    required this.note,
    required this.at,
  });

  final String reason;
  final String? note;
  final String at;
}

/// One of the images the patient attached at upload time
/// (`prescription.images` in the backend response) — the already-uploaded
/// image, not the local-pick-and-preview shape `PrescriptionImage` (upload
/// screen) covers.
class PharmacyOrderPrescriptionImage {
  const PharmacyOrderPrescriptionImage({
    required this.id,
    required this.fileUrl,
    required this.qualityCheckStatus,
  });

  final String id;
  final String fileUrl;
  final String qualityCheckStatus;
}

/// `GET /v1/pharmacy-orders`/`GET /v1/pharmacy-orders/:id` — mirrors the
/// backend's `PharmacyOrderDetail` (`clinic-reservations`
/// `pharmacy-order-detail.mapper.ts`). The list endpoint returns this exact
/// same shape per row, not a lighter summary.
class PharmacyOrderDetail {
  const PharmacyOrderDetail({
    required this.id,
    required this.status,
    required this.fulfillmentType,
    required this.createdAt,
    required this.updatedAt,
    required this.pharmacyName,
    required this.doctorName,
    required this.quote,
    required this.patientNote,
    required this.staffNote,
    required this.prescriptionImages,
    required this.rejection,
  });

  final String id;
  final String status;
  final String fulfillmentType;
  final String createdAt;
  final String updatedAt;
  /// Not returned by the backend today (no branch profile join in
  /// `buildPharmacyOrderDetail`) — always `null`, kept as a field so the UI
  /// has a single place to show it once the backend adds it.
  final String? pharmacyName;
  final String? doctorName;
  final PharmacyOrderQuote? quote;
  final String? patientNote;
  /// The order-level staff note (`order.staff_note`) — distinct from
  /// `quote.note`, which is the same underlying column surfaced a second
  /// time inside the quote payload; kept separate here because a rejected
  /// order can carry a staff note with no quote at all.
  final String? staffNote;
  final List<PharmacyOrderPrescriptionImage> prescriptionImages;
  final PharmacyOrderRejection? rejection;

  /// The patient's own approve-and-pay CTA only makes sense once a branch
  /// has priced the order — mirrors the backend's own
  /// `APPROVABLE_STATUS = 'ACCEPTED'` guard on `ApprovePharmacyOrderUseCase`.
  bool get canApprove => status == 'ACCEPTED' && quote != null;

  /// The patient's own "confirm receipt" CTA — only while a home-delivery
  /// order is actually out for delivery, mirroring the backend's
  /// `assertOrderIsOutForDelivery` guard on
  /// `ConfirmPharmacyOrderReceiptUseCase`. A pickup order (`READY_FOR_PICKUP`)
  /// is closed by pharmacy staff instead, not from this screen.
  bool get canConfirmReceipt => status == 'OUT_FOR_DELIVERY';
}
