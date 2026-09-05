/// A quote lab staff submitted for the order — present once staff has
/// reviewed and priced it, `null` while still `REQUESTED`.
class LabOrderQuote {
  const LabOrderQuote({
    required this.totalPrice,
    required this.currency,
    required this.appointmentAt,
    required this.prepInstructions,
    required this.quotedAt,
  });

  final String totalPrice;
  final String currency;
  final String appointmentAt;
  final String prepInstructions;
  final String quotedAt;
}

/// Why staff rejected the order — present only once `status` is `REJECTED`.
class LabOrderRejection {
  const LabOrderRejection({
    required this.reason,
    required this.note,
    required this.at,
  });

  final String reason;
  final String? note;
  final String at;
}

/// One uploaded result file — a lab-recorded result document
/// (`LabResultDocument`, backend `lab-order-detail.mapper.ts`). `fileUrl` is
/// a freshly signed, time-limited ImageKit URL (never persisted signed —
/// backend re-signs on every read), so it's only valid for a few minutes
/// and must not be cached across app sessions.
class LabOrderResultFile {
  const LabOrderResultFile({
    required this.id,
    required this.itemId,
    required this.fileLabel,
    required this.fileUrl,
    required this.uploadedAt,
    required this.isCritical,
  });

  final String id;
  final String? itemId;
  final String fileLabel;
  final String? fileUrl;
  final String uploadedAt;
  final bool isCritical;
}

/// One requested test/analysis line on the order — either from direct
/// catalog selection or (today, the only path `med-super` actually exercises)
/// added later by staff after transcribing an uploaded prescription.
class LabOrderItem {
  const LabOrderItem({
    required this.id,
    required this.catalogCode,
    required this.displayName,
    required this.unitPrice,
    required this.resultState,
  });

  final String id;
  final String catalogCode;
  final String displayName;
  final String? unitPrice;
  final String resultState;
}

/// `GET /v1/lab-orders`/`GET /v1/lab-orders/:id` — a trimmed view of the
/// backend's `LabOrderDetail` (`clinic-reservations`
/// `lab-order-detail.mapper.ts`): enough for the patient-facing tracking
/// screen (status, quote, booking code, item results), not the full staff
/// console shape (no custody events/notes/patient summary — those back
/// `medsuper-laboratory-dashboard`'s own staff-only views).
class LabOrderDetail {
  const LabOrderDetail({
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
    required this.results,
  });

  final String id;
  final String status;
  final String collectionType;
  final String createdAt;
  final String updatedAt;

  /// Not resolved to a branch name/address by the backend's list/detail
  /// response (no branch join in `buildLabOrderDetail`) — kept as an id so
  /// the UI has a single place to reconcile it once/if the backend adds one,
  /// same `not_persisted`-style gap `PharmacyOrderDetail.pharmacyName`
  /// already documents for the pharmacy side.
  final String branchId;
  final List<LabOrderItem> items;
  final LabOrderQuote? quote;

  /// Issued by `ConfirmLabBookingUseCase` (`QUOTED --> AWAITING_SAMPLE`) —
  /// null until then.
  final String? bookingCode;
  final LabOrderRejection? rejection;
  final bool recollectionRequired;
  final List<LabOrderResultFile> results;
}
