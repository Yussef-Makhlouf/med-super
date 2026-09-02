import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/pharmacy_booking/data/models/prescription_upload_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';

class PrescriptionRemoteDatasource {
  PrescriptionRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PrescriptionUploadResult> upload({
    required List<String> fileUrls,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.prescriptions}/upload',
      data: {'fileUrls': fileUrls, if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return PrescriptionUploadDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}
