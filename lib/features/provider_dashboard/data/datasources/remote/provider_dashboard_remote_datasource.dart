import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import '../../models/appointment_dto.dart';
import '../../models/doctor_account_profile_dto.dart';
import '../../models/doctor_notification_dto.dart';
import '../../models/patient_dto.dart';

abstract class ProviderDashboardRemoteDatasource {
  Future<List<AppointmentDto>> getAppointments({
    DateTime? date,
    String? status,
  });

  Future<AppointmentDto> acceptAppointment(String id);

  Future<AppointmentDto> rejectAppointment(String id);

  Future<AppointmentDto> createAppointment({
    required String patientName,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  });

  Future<List<PatientDto>> getPatients({
    String? query,
    String? filter,
  });

  Future<List<DoctorNotificationDto>> getNotifications();

  Future<void> markNotificationRead(String id);

  Future<DoctorAccountProfileDto> getDoctorAccount();
}

class ProviderDashboardRemoteDatasourceImpl
    implements ProviderDashboardRemoteDatasource {
  ProviderDashboardRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AppointmentDto>> getAppointments({
    DateTime? date,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerAppointments,
      queryParameters: {
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final items = (response.data?['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => AppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AppointmentDto> acceptAppointment(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerAppointments}/$id/accept',
    );
    return AppointmentDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<AppointmentDto> rejectAppointment(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.providerAppointments}/$id/reject',
    );
    return AppointmentDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<AppointmentDto> createAppointment({
    required String patientName,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerAppointments,
      data: {
        'patient_name': patientName,
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
      },
    );
    return AppointmentDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<List<PatientDto>> getPatients({
    String? query,
    String? filter,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerPatients,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
    );

    final items = (response.data?['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => PatientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DoctorNotificationDto>> getNotifications() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerNotifications,
    );

    final items = (response.data?['items'] as List<dynamic>?) ?? [];
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

  @override
  Future<DoctorAccountProfileDto> getDoctorAccount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerMe,
    );

    return DoctorAccountProfileDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }
}
