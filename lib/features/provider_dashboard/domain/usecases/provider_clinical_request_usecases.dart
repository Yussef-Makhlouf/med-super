import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import '../entities/provider_clinical_request.dart';
import '../repositories/provider_clinical_requests_repository.dart';

class ProviderClinicalRequestUseCases {
  const ProviderClinicalRequestUseCases(this._repository);
  final ProviderClinicalRequestsRepository _repository;

  Future<ProviderPrescriptionResult> createPrescription({
    required String patientId,
    required List<ProviderPrescriptionItem> items,
    String? appointmentId,
    String? notes,
  }) => _repository.createPrescription(
    patientId: patientId,
    items: items,
    appointmentId: appointmentId,
    notes: notes,
  );
  Future<ProviderPrescriptionBatchResult> createPrescriptionBatch(
    List<ProviderPrescriptionRequest> requests,
  ) => _repository.createPrescriptionBatch(requests);
  Future<List<ProviderPrescription>> prescriptions() =>
      _repository.listPrescriptions();
  Future<ProviderPrescription> prescription(String id) =>
      _repository.getPrescription(id);
  Future<void> decidePrescription({
    required String id,
    required int version,
    required bool approve,
    String? reason,
  }) => _repository.decidePrescription(
    id: id,
    version: version,
    approve: approve,
    reason: reason,
  );
  Future<List<ProviderLabTest>> searchLabCatalog(String search) =>
      _repository.searchLabCatalog(search);
  Future<ProviderLabRequestResult> createLabOrder({
    required String patientId,
    required String labBranchId,
    required String collectionType,
    required List<String> testCodes,
    String? appointmentId,
  }) => _repository.createLabOrder(
    patientId: patientId,
    labBranchId: labBranchId,
    collectionType: collectionType,
    testCodes: testCodes,
    appointmentId: appointmentId,
  );
  Future<ProviderLabBatchResult> createLabOrderBatch(
    List<ProviderLabRequest> requests,
  ) => _repository.createLabOrderBatch(requests);
  Future<List<LabOrderDetail>> labOrders() => _repository.listLabOrders();
  Future<List<PharmacyOrderDetail>> pharmacyOrders() =>
      _repository.listPharmacyOrders();
  Future<ProviderPharmacyRequestResult> createPharmacyOrder({
    required String patientId,
    required String prescriptionId,
    required String fulfillmentType,
    String? pharmacyBranchId,
  }) => _repository.createPharmacyOrder(
    patientId: patientId,
    prescriptionId: prescriptionId,
    fulfillmentType: fulfillmentType,
    pharmacyBranchId: pharmacyBranchId,
  );
}
