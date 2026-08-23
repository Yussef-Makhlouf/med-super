import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';

class ProviderRegistrationRemoteDatasource {
  ProviderRegistrationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<void> submit(
    DoctorRegistrationDraft draft, {
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerRegistrationSubmit,
      data: {
        'full_name': draft.fullName,
        'specialty': draft.specialty,
        'specialty_label': specialtyLabel,
        'degree': draft.degree,
        'email': draft.email,
        'phone': phone,
        'photo_data_uri': draft.profilePhotoDataUri,
        'experience_years': draft.experienceYears,
        'bio': draft.bio,
        'license_number': draft.licenseNumber,
        'documents': draft.documents.map((d) => d.fileName).toList(),
        'clinic_name': draft.clinicName,
        'clinic_address': draft.clinicAddress,
        'city': draft.city,
        'city_label': cityLabel,
        'region_code': draft.regionCode,
        'consultation_fee': draft.consultationFee,
        'working_days': draft.workingDays
            .map(
              (d) => {
                'day': d.day.name,
                'is_enabled': d.isEnabled,
                'from': d.from == null
                    ? null
                    : {'hour': d.from!.hour, 'minute': d.from!.minute},
                'to': d.to == null
                    ? null
                    : {'hour': d.to!.hour, 'minute': d.to!.minute},
              },
            )
            .toList(),
      },
    );
  }
}
