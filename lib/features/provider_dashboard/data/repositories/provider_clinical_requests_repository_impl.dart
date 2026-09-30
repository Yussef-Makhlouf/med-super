import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import '../../domain/entities/provider_clinical_request.dart';
import '../../domain/repositories/provider_clinical_requests_repository.dart';
import '../datasources/remote/provider_clinical_requests_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';

class ProviderClinicalRequestsRepositoryImpl
    implements ProviderClinicalRequestsRepository {
  const ProviderClinicalRequestsRepositoryImpl(this._remote);
  final ProviderClinicalRequestsRemoteDatasource _remote;

  @override
  Future<PrescriptionUploadResult> uploadClinicalDocument({
    required String patientId,
    required String documentType,
    required List<PrescriptionImage> images,
    String? appointmentId,
    String? notes,
  }) => _remote.uploadClinicalDocument(
    patientId: patientId,
    documentType: documentType,
    images: images,
    appointmentId: appointmentId,
    notes: notes,
  );

  @override
  Future<ProviderPrescriptionResult> createPrescription({
    required String patientId,
    required List<ProviderPrescriptionItem> items,
    String? appointmentId,
    String? notes,
  }) => _remote.createPrescription(
    patientId: patientId,
    items: items,
    appointmentId: appointmentId,
    notes: notes,
  );
  @override
  Future<ProviderPrescriptionBatchResult> createPrescriptionBatch(
    List<ProviderPrescriptionRequest> requests,
  ) => _remote.createPrescriptionBatch(requests);
  @override
  Future<List<ProviderPrescription>> listPrescriptions() =>
      _remote.listPrescriptions();
  @override
  Future<ProviderPrescription> getPrescription(String id) =>
      _remote.getPrescription(id);
  @override
  Future<void> decidePrescription({
    required String id,
    required int version,
    required bool approve,
    String? reason,
  }) => _remote.decidePrescription(
    id: id,
    version: version,
    approve: approve,
    reason: reason,
  );
  @override
  @override
  Future<ProviderLabRequestResult> createLabOrder({
    required String patientId,
    required String labBranchId,
    required String collectionType,
    required String prescriptionId,
    String? appointmentId,
  }) => _remote.createLabOrder(
    patientId: patientId,
    labBranchId: labBranchId,
    collectionType: collectionType,
    prescriptionId: prescriptionId,
    appointmentId: appointmentId,
  );
  @override
  Future<ProviderLabBatchResult> createLabOrderBatch(
    List<ProviderLabRequest> requests,
  ) => _remote.createLabOrderBatch(requests);
  @override
  Future<List<LabOrderDetail>> listLabOrders() => _remote.listLabOrders();
  @override
  Future<List<PharmacyOrderDetail>> listPharmacyOrders() =>
      _remote.listPharmacyOrders();
  @override
  Future<ProviderPharmacyRequestResult> createPharmacyOrder({
    required String patientId,
    required String prescriptionId,
    required String fulfillmentType,
    String? appointmentId,
    String? pharmacyBranchId,
  }) => _remote.createPharmacyOrder(
    patientId: patientId,
    prescriptionId: prescriptionId,
    fulfillmentType: fulfillmentType,
    appointmentId: appointmentId,
    pharmacyBranchId: pharmacyBranchId,
  );
}
