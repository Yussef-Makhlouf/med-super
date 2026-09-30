import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:med_super/core/constants/api_paths.dart';
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
              // Without an explicit content type, Dio defaults to
              // `application/octet-stream` — the backend's
              // `assertValidMediaFiles` allowlists only jpeg/png/pdf
              // (`MEDIA_CONSTANTS.DOCUMENT_MIME_TYPES`) and rejects anything
              // else with `400 UNSUPPORTED_FILE_TYPE`.
              contentType: _mimeTypeFor(image.path),
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
              contentType: _mimeTypeFor(image.path),
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

  /// Maps a picked file's extension to one of the backend's exact allowed
  /// MIME types (`MEDIA_CONSTANTS.DOCUMENT_MIME_TYPES`: jpeg/png/pdf) — the
  /// image picker only offers `FileType.image`, so `.jpg`/`.jpeg`/`.png` are
  /// the only extensions expected in practice; anything else falls back to
  /// `image/jpeg` rather than leaving the content type unset (which Dio
  /// would otherwise default to `application/octet-stream`, always rejected
  /// by `assertValidMediaFiles`).
  static MediaType _mimeTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'pdf' => MediaType('application', 'pdf'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
