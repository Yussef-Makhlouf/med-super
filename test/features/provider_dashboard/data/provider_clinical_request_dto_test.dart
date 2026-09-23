import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/data/datasources/remote/provider_clinical_requests_remote_datasource.dart';
import 'package:med_super/features/provider_dashboard/data/models/provider_clinical_request_dto.dart';

void main() {
  test(
    'maps provider prescription decision state, version and item details',
    () {
      final prescription = ProviderPrescriptionDto.fromJson({
        'id': 'rx-1',
        'patientId': 'patient-1',
        'status': 'PENDING_DOCTOR_APPROVAL',
        'version': 3,
        'createdAt': '2026-09-23T10:00:00.000Z',
        'appointmentId': 'appointment-1',
        'createdByRole': 'CLINIC_STAFF',
        'items': [
          {
            'drugName': 'Amoxicillin',
            'dose': '500 mg',
            'frequency': '3 times daily',
            'durationDays': 7,
            'quantity': 21,
          },
        ],
      }).toEntity();

      expect(prescription.pendingApproval, isTrue);
      expect(prescription.signed, isFalse);
      expect(prescription.version, 3);
      expect(prescription.patientId, 'patient-1');
      expect(prescription.items.single.drugName, 'Amoxicillin');
      expect(prescription.items.single.durationDays, 7);
    },
  );

  test('maps the provider lab catalog contract', () {
    final test = ProviderLabTestDto.fromJson({
      'code': 'CBC',
      'displayName': 'Complete Blood Count',
    }).toEntity();

    expect(test.code, 'CBC');
    expect(test.displayName, 'Complete Blood Count');
  });

  test(
    'omits an absent pharmacy branch from provider pharmacy requests',
    () async {
      final requests = <Map<String, dynamic>>[];
      final datasource = ProviderClinicalRequestsRemoteDatasource(
        _recordingDio(requests.add),
      );

      await datasource.createPharmacyOrder(
        patientId: 'patient-1',
        prescriptionId: 'prescription-1',
        fulfillmentType: 'DELIVERY',
      );

      expect(requests.single, {
        'patientId': 'patient-1',
        'prescriptionId': 'prescription-1',
        'fulfillmentType': 'DELIVERY',
      });
    },
  );

  test(
    'includes a supplied pharmacy branch in provider pharmacy requests',
    () async {
      final requests = <Map<String, dynamic>>[];
      final datasource = ProviderClinicalRequestsRemoteDatasource(
        _recordingDio(requests.add),
      );

      await datasource.createPharmacyOrder(
        patientId: 'patient-1',
        prescriptionId: 'prescription-1',
        fulfillmentType: 'PICKUP',
        pharmacyBranchId: 'branch-1',
      );

      expect(requests.single['pharmacyBranchId'], 'branch-1');
    },
  );
}

Dio _recordingDio(void Function(Map<String, dynamic>) record) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          record(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {'id': 'pharmacy-order-1', 'status': 'RECEIVED'},
            ),
          );
        },
      ),
    );
}
