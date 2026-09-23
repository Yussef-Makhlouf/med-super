class ProviderPrescriptionItem {
  const ProviderPrescriptionItem({
    required this.drugName,
    required this.quantity,
    this.dose,
    this.frequency,
    this.durationDays,
  });

  final String drugName;
  final int quantity;
  final String? dose;
  final String? frequency;
  final int? durationDays;
}

class ProviderPrescription {
  const ProviderPrescription({
    required this.id,
    required this.patientId,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.items,
    this.appointmentId,
    this.notes,
    this.source,
    this.createdByRole,
    this.rejectionReason,
  });

  final String id;
  final String patientId;
  final String status;
  final int version;
  final DateTime? createdAt;
  final List<ProviderPrescriptionItem> items;
  final String? appointmentId;
  final String? notes;
  final String? source;
  final String? createdByRole;
  final String? rejectionReason;

  bool get pendingApproval => status == 'PENDING_DOCTOR_APPROVAL';
  bool get signed => status == 'ACCEPTED';
}

class ProviderPrescriptionResult {
  const ProviderPrescriptionResult({
    required this.prescriptionId,
    required this.status,
  });

  final String prescriptionId;
  final String status;
}

/// One patient-specific prescription payload in a batch.  A batch is only a
/// transport/grouping concern: every entry becomes its own prescription.
class ProviderPrescriptionRequest {
  const ProviderPrescriptionRequest({
    required this.patientId,
    required this.items,
    this.appointmentId,
    this.notes,
  });

  final String patientId;
  final List<ProviderPrescriptionItem> items;
  final String? appointmentId;
  final String? notes;
}

class ProviderPrescriptionBatchResult {
  const ProviderPrescriptionBatchResult({
    required this.batchId,
    required this.results,
  });

  final String batchId;
  final List<ProviderPrescriptionBatchItemResult> results;
}

class ProviderPrescriptionBatchItemResult extends ProviderPrescriptionResult {
  const ProviderPrescriptionBatchItemResult({
    required this.patientId,
    required super.prescriptionId,
    required super.status,
  });

  final String patientId;
}

class ProviderLabTest {
  const ProviderLabTest({required this.code, required this.displayName});
  final String code;
  final String displayName;
}

class ProviderLabRequestResult {
  const ProviderLabRequestResult({
    required this.labOrderId,
    required this.status,
  });
  final String labOrderId;
  final String status;
}

/// One independently authorized lab request in a provider batch.
class ProviderLabRequest {
  const ProviderLabRequest({
    required this.patientId,
    required this.labBranchId,
    required this.collectionType,
    required this.testCodes,
    this.prescriptionId,
    this.appointmentId,
  });

  final String patientId;
  final String labBranchId;
  final String collectionType;
  final List<String> testCodes;
  final String? prescriptionId;
  final String? appointmentId;
}

class ProviderLabBatchResult {
  const ProviderLabBatchResult({required this.batchId, required this.results});

  final String batchId;
  final List<ProviderLabBatchItemResult> results;
}

class ProviderLabBatchItemResult extends ProviderLabRequestResult {
  const ProviderLabBatchItemResult({
    required this.patientId,
    required super.labOrderId,
    required super.status,
  });

  final String patientId;
}

class ProviderPharmacyRequestResult {
  const ProviderPharmacyRequestResult({
    required this.pharmacyOrderId,
    required this.status,
  });
  final String pharmacyOrderId;
  final String status;
}
