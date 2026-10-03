import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/utils/upload_media_type.dart';
import 'package:med_super/features/pharmacy_booking/data/models/prescription_upload_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';

class PrescriptionRemoteDatasource {
  PrescriptionRemoteDatasource(this._dio);

  final Dio _dio;

  /// `multipart/form-data` to `POST /v1/prescriptions/upload` — field name
  /// `files` (array, backend's `FilesInterceptor('files', ...)`), matching
  /// `PrescriptionsController.upload` exactly (File 12 Part 37).
  Future<PrescriptionUploadResult> upload({
    required List<PrescriptionImage> images,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'files': images
          .where((image) => image.bytes != null)
          .map(
            (image) => MultipartFile.fromBytes(
              image.bytes!,
              filename: image.path,
              // Labelled from the bytes, not the name: the backend checks
              // the content against the declared type (jpeg/png/pdf only),
              // and Dio would otherwise send `application/octet-stream`.
              contentType: UploadMediaType.forUpload(image.bytes!, image.path),
            ),
          )
          .toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.prescriptions}/upload',
      data: formData,
    );
    return PrescriptionUploadDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  /// Provider upload counterpart to the patient flow. Uses the identical
  /// multipart `files` contract and private-media pipeline while adding the
  /// patient scope and explicit document purpose required by the backend.
  Future<PrescriptionUploadResult> uploadForProvider({
    required String patientId,
    required String documentType,
    required List<PrescriptionImage> images,
    String? appointmentId,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'patientId': patientId,
      'documentType': documentType,
      ...?((appointmentId != null) ? {'appointmentId': appointmentId} : null),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'files': images
          .where((image) => image.bytes != null)
          .map(
            (image) => MultipartFile.fromBytes(
              image.bytes!,
              filename: image.path,
              contentType: UploadMediaType.forUpload(image.bytes!, image.path),
            ),
          )
          .toList(growable: false),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerPrescriptions}/upload',
      data: formData,
    );
    return PrescriptionUploadDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}
