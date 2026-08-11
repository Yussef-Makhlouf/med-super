import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';

class ProviderRegistrationRemoteDatasource {
  ProviderRegistrationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<void> submit(DoctorRegistrationDraft draft) async {
    await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerRegistrationSubmit,
      data: {
        'full_name': draft.fullName,
        'specialty': draft.specialty,
        'degree': draft.degree,
        'experience_years': draft.experienceYears,
        'bio': draft.bio,
        'documents': draft.documents.map((d) => d.fileName).toList(),
        'clinic_name': draft.clinicName,
        'clinic_address': draft.clinicAddress,
        'city': draft.city,
        'consultation_fee': draft.consultationFee,
      },
    );
  }
}
