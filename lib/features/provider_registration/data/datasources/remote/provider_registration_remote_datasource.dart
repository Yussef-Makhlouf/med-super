import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';

class ProviderRegistrationRemoteDatasource {
  ProviderRegistrationRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /v1/provider/registration/status` — returns `null` on a `404`
  /// (never self-registered as a doctor), not an error; any other failure
  /// still throws, for the repository to map to a `Result.err`.
  Future<String?> getStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.providerRegistrationStatus,
      );
      return response.data?['status'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// `POST /v1/provider-verification-documents`, `multipart/form-data`,
  /// mirroring `PrescriptionRemoteDatasource.upload` — field name `file`
  /// (single, backend's `FileInterceptor('file', ...)`), plus the
  /// `providerType`/`providerId`/`docType` text fields
  /// `VerificationDocumentsController.upload` expects. Called once per
  /// document right after registration submits and a real `doctorId`
  /// exists — a `DOCTOR` caller may only target their own doctor id (File 12
  /// Part 48), which self-registration always satisfies.
  Future<void> uploadVerificationDocument({
    required String doctorId,
    required UploadedDocument document,
  }) async {
    final bytes = document.bytes;
    if (bytes == null) return;
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: document.fileName,
        contentType: _mimeTypeFor(document.fileName),
      ),
      'providerType': 'DOCTOR',
      'providerId': doctorId,
      'docType': _docTypeFor(document.type),
    });
    await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerVerificationDocuments,
      data: formData,
    );
  }

  static MediaType _mimeTypeFor(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'pdf' => MediaType('application', 'pdf'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  static String _docTypeFor(DocumentType type) => switch (type) {
    DocumentType.medicalLicense => 'MEDICAL_LICENSE',
    DocumentType.nationalId => 'NATIONAL_ID',
    DocumentType.specialtyCertificate => 'SPECIALTY_CERTIFICATE',
    DocumentType.profilePhoto => 'PROFILE_PHOTO',
  };

  /// ISO-8601 weekday (1=Monday…7=Sunday, matching the backend's
  /// `CreateScheduleTemplateDto.weekday`/`WorkingDayDto.weekday`) for each
  /// [Weekday] enum value — the enum is declared in Saturday-first (Egypt
  /// week start) order, which is NOT ISO order, so this cannot be derived
  /// from `Weekday.index`.
  static const _isoWeekdayFor = {
    Weekday.monday: 1,
    Weekday.tuesday: 2,
    Weekday.wednesday: 3,
    Weekday.thursday: 4,
    Weekday.friday: 5,
    Weekday.saturday: 6,
    Weekday.sunday: 7,
  };

  static String _hhmm(ClinicTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// `SubmitProviderRegistrationDto.working_days` (File 12 Part 48) — one
  /// entry per enabled day with both a start and end time; a day missing
  /// either time is dropped rather than sent as a half-filled entry that
  /// would fail the backend's `@Matches(HH_MM)` validation.
  static List<Map<String, dynamic>> _workingDaysPayload(
    List<ClinicWorkingDay> workingDays,
  ) => workingDays
      .where((d) => d.isEnabled && d.from != null && d.to != null)
      .map(
        (d) => {
          'weekday': _isoWeekdayFor[d.day],
          'startTime': _hhmm(d.from!),
          'endTime': _hhmm(d.to!),
          // No per-slot-duration/buffer UI exists yet in the working-hours
          // step — these match `CreateScheduleTemplateDto`'s defaults
          // (Admin-created templates commonly use a 30-minute slot).
          'slotDurationMinutes': 30,
          'bufferMinutes': 0,
        },
      )
      .toList();

  /// Returns the newly created `doctorId` (`SelfRegisterProviderResult`,
  /// `provider-registration.controller.ts`) so the caller can immediately
  /// upload verification documents against it.
  Future<String> submit(
    DoctorRegistrationDraft draft, {
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
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
        'clinic_name': draft.clinicName,
        'clinic_address': draft.clinicAddress,
        'city': draft.city,
        'city_label': cityLabel,
        'region_code': draft.regionCode,
        'consultation_fee': draft.consultationFee,
        'working_days': _workingDaysPayload(draft.workingDays),
      },
    );
    return response.data?['doctorId'] as String? ?? '';
  }
}
