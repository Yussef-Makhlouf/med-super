import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import '../../models/doctor_account_profile_dto.dart';
import '../../models/doctor_appointment_dto.dart';
import '../../models/doctor_clinic_dto.dart';
import '../../models/doctor_notification_dto.dart';
import '../../models/doctor_schedule_template_dto.dart';
import '../../models/patient_dto.dart';
import '../../../domain/entities/doctor_appointment.dart';
import '../../../domain/entities/doctor_schedule_template.dart';

/// Every method below maps 1:1 onto a real `clinic-reservations` route
/// (File 12 Part 49), with two documented exceptions that remain mock-only:
/// [getPatients] and the notification pair. Nothing here invents a path.
///
/// `EnvelopeInterceptor` has already unwrapped the backend's
/// `{success, data, requestId, correlationId}` success envelope, so
/// `response.data` is the `data` payload itself.
abstract class ProviderDashboardRemoteDatasource {
  // --- Profile (GET/PATCH /v1/doctors/me) ---

  Future<DoctorAccountProfileDto> getDoctorAccount();

  /// `name`/`specialty`/`licenseNumber` are deliberately not parameters —
  /// `PATCH /v1/doctors/me` only accepts `bio`/`degree`/`experienceYears`
  /// (File 12 Part 45); a doctor can't re-specialize, re-license, or
  /// rename themselves through this endpoint.
  Future<DoctorAccountProfileDto> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  });

  // --- Clinics and branches (/v1/doctors/me/clinics) ---

  Future<List<DoctorClinicDto>> getMyClinics();

  Future<DoctorClinicDto> updateMyClinicBranch(
    String branchId,
    UpdateDoctorBranchRequestDto body,
  );

  Future<DoctorClinicDto> updateMyAffiliationStatus(
    String affiliationId, {
    required bool active,
  });

  // --- Availability (/v1/doctors/me/schedule-templates) ---

  Future<List<DoctorScheduleTemplateDto>> getMyScheduleTemplates({
    String? affiliationId,
  });

  Future<DoctorScheduleTemplateDto> createMyScheduleTemplate(
    NewDoctorScheduleTemplate template,
  );

  Future<DoctorScheduleTemplateDto> updateMyScheduleTemplate(
    String templateId,
    DoctorScheduleTemplatePatch patch,
  );

  Future<void> deleteMyScheduleTemplate(String templateId, {int? version});

  // --- Appointments (/v1/doctors/me/appointments) ---

  Future<DoctorAppointmentPageDto> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  });

  Future<DoctorAppointmentDto> getMyAppointment(String appointmentId);

  Future<CancelAppointmentResultDto> cancelMyAppointment(
    String appointmentId, {
    String? note,
  });

  Future<RescheduleAppointmentResultDto> rescheduleMyAppointment(
    String appointmentId, {
    required String newSlotId,
  });

  // --- Still mock-only: no backend route exists (see STATUS.md) ---

  Future<List<PatientDto>> getPatients({String? query, String? filter});

  Future<List<DoctorNotificationDto>> getNotifications();

  Future<void> markNotificationRead(String id);
}

class ProviderDashboardRemoteDatasourceImpl
    implements ProviderDashboardRemoteDatasource {
  ProviderDashboardRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  static Map<String, dynamic> _obj(Response<Map<String, dynamic>> response) =>
      response.data ?? const <String, dynamic>{};

  @override
  Future<DoctorAccountProfileDto> getDoctorAccount() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.doctorMe);
    return DoctorAccountProfileDto.fromJson(_obj(response));
  }

  @override
  Future<DoctorAccountProfileDto> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.doctorMe,
      data: {
        if (bio != null) 'bio': bio,
        if (degree != null) 'degree': degree,
        if (yearsOfExperience != null) 'experienceYears': yearsOfExperience,
      },
    );
    return DoctorAccountProfileDto.fromJson(_obj(response));
  }

  @override
  Future<List<DoctorClinicDto>> getMyClinics() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.doctorMeClinics,
    );
    final items = (_obj(response)['items'] as List<dynamic>?) ?? const [];
    return items
        .map((e) => DoctorClinicDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DoctorClinicDto> updateMyClinicBranch(
    String branchId,
    UpdateDoctorBranchRequestDto body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.doctorMeClinicBranches}/$branchId',
      data: body.toJson(),
    );
    return DoctorClinicDto.fromJson(_obj(response));
  }

  @override
  Future<DoctorClinicDto> updateMyAffiliationStatus(
    String affiliationId, {
    required bool active,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.doctorMeAffiliations}/$affiliationId',
      data: {'status': active ? 'ACTIVE' : 'PAUSED'},
    );
    return DoctorClinicDto.fromJson(_obj(response));
  }

  @override
  Future<List<DoctorScheduleTemplateDto>> getMyScheduleTemplates({
    String? affiliationId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.doctorMeScheduleTemplates,
      queryParameters: {
        if (affiliationId != null) 'affiliationId': affiliationId,
      },
    );
    final items = (_obj(response)['items'] as List<dynamic>?) ?? const [];
    return items
        .map(
          (e) => DoctorScheduleTemplateDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<DoctorScheduleTemplateDto> createMyScheduleTemplate(
    NewDoctorScheduleTemplate template,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.doctorMeScheduleTemplates,
      data: DoctorScheduleTemplateDto.createBody(template),
    );
    return DoctorScheduleTemplateDto.fromJson(_obj(response));
  }

  @override
  Future<DoctorScheduleTemplateDto> updateMyScheduleTemplate(
    String templateId,
    DoctorScheduleTemplatePatch patch,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.doctorMeScheduleTemplates}/$templateId',
      data: DoctorScheduleTemplateDto.patchBody(patch),
    );
    return DoctorScheduleTemplateDto.fromJson(_obj(response));
  }

  @override
  Future<void> deleteMyScheduleTemplate(String templateId, {int? version}) async {
    await _dio.delete<void>(
      '${ApiPaths.doctorMeScheduleTemplates}/$templateId',
      queryParameters: {if (version != null) 'version': version},
    );
  }

  @override
  Future<DoctorAppointmentPageDto> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.doctorMeAppointments,
      queryParameters: {
        // Bounds are sent as UTC ISO-8601 — the backend filters on the slot's
        // `start_at`, which is timestamptz.
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (status?.wireValue != null) 'status': status!.wireValue,
        if (clinicBranchId != null) 'clinicBranchId': clinicBranchId,
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
    );
    return DoctorAppointmentPageDto.fromJson(_obj(response));
  }

  @override
  Future<DoctorAppointmentDto> getMyAppointment(String appointmentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.doctorMeAppointments}/$appointmentId',
    );
    return DoctorAppointmentDto.fromJson(_obj(response));
  }

  @override
  Future<CancelAppointmentResultDto> cancelMyAppointment(
    String appointmentId, {
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.doctorMeAppointments}/$appointmentId/cancel',
      // `PROVIDER_REQUEST` is the only reason this route accepts — it is what
      // waives the cancellation fee entirely (File 12 Part 49.8). Sending
      // anything else is a 400.
      data: {
        'reason': 'PROVIDER_REQUEST',
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return CancelAppointmentResultDto.fromJson(_obj(response));
  }

  @override
  Future<RescheduleAppointmentResultDto> rescheduleMyAppointment(
    String appointmentId, {
    required String newSlotId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.doctorMeAppointments}/$appointmentId/reschedule',
      data: {'newSlotId': newSlotId},
    );
    return RescheduleAppointmentResultDto.fromJson(_obj(response));
  }

  @override
  Future<List<PatientDto>> getPatients({String? query, String? filter}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerPatients,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
    );

    final items = (_obj(response)['items'] as List<dynamic>?) ?? const [];
    return items
        .map((e) => PatientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DoctorNotificationDto>> getNotifications() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerNotifications,
    );

    final items = (_obj(response)['items'] as List<dynamic>?) ?? const [];
    return items
        .map((e) => DoctorNotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerNotifications}/$id/read',
    );
  }
}
