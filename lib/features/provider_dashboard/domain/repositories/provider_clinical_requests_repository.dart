import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import '../entities/provider_clinical_request.dart';

abstract interface class ProviderClinicalRequestsRepository {
  Future<ProviderPrescriptionResult> createPrescription({
    required String patientId,
    required List<ProviderPrescriptionItem> items,
    String? appointmentId,
    String? notes,
  });
  Future<ProviderPrescriptionBatchResult> createPrescriptionBatch(
    List<ProviderPrescriptionRequest> requests,
  );
  Future<List<ProviderPrescription>> listPrescriptions();
  Future<ProviderPrescription> getPrescription(String id);
  Future<void> decidePrescription({
    required String id,
    required int version,
    required bool approve,
    String? reason,
  });
  Future<List<ProviderLabTest>> searchLabCatalog(String search);
  Future<ProviderLabRequestResult> createLabOrder({
    required String patientId,
    required String labBranchId,
    required String collectionType,
    required List<String> testCodes,
    String? appointmentId,
  });
  Future<ProviderLabBatchResult> createLabOrderBatch(
    List<ProviderLabRequest> requests,
  );
  Future<List<LabOrderDetail>> listLabOrders();
  Future<List<PharmacyOrderDetail>> listPharmacyOrders();
  Future<ProviderPharmacyRequestResult> createPharmacyOrder({
    required String patientId,
    required String prescriptionId,
    required String fulfillmentType,
    String? pharmacyBranchId,
  });
}
