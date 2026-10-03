import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/data/datasources/remote/provider_clinical_requests_remote_datasource.dart';
import 'package:med_super/features/provider_dashboard/data/models/provider_clinical_request_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';

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

  test('maps private prescription image URLs for provider history', () {
    final prescription = ProviderPrescriptionDto.fromJson({
      'id': 'rx-photo-1',
      'patientId': 'patient-1',
      'status': 'ACCEPTED',
      'images': [
        {'id': 'image-1', 'fileUrl': 'https://private.example/image-1'},
      ],
    }).toEntity();

    expect(prescription.images, hasLength(1));
    expect(prescription.images.single.url, 'https://private.example/image-1');
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

  test(
    'uploads a provider referral with the backend multipart field names',
    () async {
      RequestOptions? sent;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sent = options;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  data: const {
                    'prescriptionId': 'referral-1',
                    'status': 'QUALITY_CHECK_PASSED',
                  },
                ),
              );
            },
          ),
        );

      final result = await ProviderClinicalRequestsRemoteDatasource(dio)
          .uploadClinicalDocument(
            patientId: 'patient-1',
            documentType: 'LAB_REFERRAL',
            images: [
              PrescriptionImage(
                id: 'image-1',
                path: 'referral.png',
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ],
          );

      expect(sent?.path, '/v1/prescriptions/provider/upload');
      final form = sent?.data as FormData;
      expect(Map.fromEntries(form.fields)['patientId'], 'patient-1');
      expect(Map.fromEntries(form.fields)['documentType'], 'LAB_REFERRAL');
      expect(form.files.single.key, 'files');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      expect(result.prescriptionId, 'referral-1');
    },
  );

  test(
    'sends the observed version and reason when a doctor rejects a draft',
    () async {
      RequestOptions? sent;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sent = options;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  data: const {},
                ),
              );
            },
          ),
        );

      await ProviderClinicalRequestsRemoteDatasource(dio).decidePrescription(
        id: 'prescription-1',
        version: 3,
        approve: false,
        reason: 'Needs correction',
      );

      expect(sent?.path, '/v1/prescriptions/provider/prescription-1/reject');
      expect(sent?.data, {'expectedVersion': 3, 'reason': 'Needs correction'});
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
