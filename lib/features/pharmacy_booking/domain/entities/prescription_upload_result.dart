/// Result of `POST /v1/prescriptions/upload` — mirrors the backend's
/// `UploadPrescriptionResult` (File 12 Part 37.1). `status` is the real
/// post-quality-check value, not a placeholder "submitted" state.
class PrescriptionUploadResult {
  const PrescriptionUploadResult({
    required this.prescriptionId,
    required this.status,
  });

  final String prescriptionId;
  final String status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionUploadResult &&
          other.prescriptionId == prescriptionId &&
          other.status == status);

  @override
  int get hashCode => Object.hash(prescriptionId, status);
}
