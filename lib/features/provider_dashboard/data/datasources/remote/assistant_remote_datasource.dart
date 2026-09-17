import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import '../../models/assistant_dto.dart';
import '../../models/provisioned_assistant_dto.dart';

abstract class AssistantRemoteDatasource {
  /// GET /v1/provider/assistants — list all assistants for the caller's clinic.
  Future<List<AssistantDto>> getAssistants();

  /// POST /v1/provider/assistants — provision a new assistant account.
  /// Returns [ProvisionedAssistantDto] which includes the one-time password.
  Future<ProvisionedAssistantDto> createAssistant({
    required String phone,
    required String displayName,
    String? title,
    String? subtitle,
    required List<String> clinicBranchIds,
  });

  /// PATCH /v1/provider/assistants/:id — update display name, status,
  /// title/subtitle and/or assigned branches (full replace when provided).
  Future<AssistantDto> updateAssistant({
    required String id,
    String? displayName,
    String? status,
    String? password,
    String? title,
    String? subtitle,
    List<String>? clinicBranchIds,
  });

  /// DELETE /v1/provider/assistants/:id — deactivate (soft-delete) an assistant.
  Future<void> deleteAssistant(String id);
}

class AssistantRemoteDatasourceImpl implements AssistantRemoteDatasource {
  AssistantRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AssistantDto>> getAssistants() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.providerAssistants,
    );
    final items = (response.data?['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => AssistantDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProvisionedAssistantDto> createAssistant({
    required String phone,
    required String displayName,
    String? title,
    String? subtitle,
    required List<String> clinicBranchIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerAssistants,
      data: {
        'phone': phone,
        'display_name': displayName,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'clinic_branch_ids': clinicBranchIds,
      },
    );
    return ProvisionedAssistantDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<AssistantDto> updateAssistant({
    required String id,
    String? displayName,
    String? status,
    String? password,
    String? title,
    String? subtitle,
    List<String>? clinicBranchIds,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.providerAssistants}/$id',
      data: {
        if (displayName != null) 'display_name': displayName,
        if (status != null) 'status': status,
        if (password != null) 'password': password,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (clinicBranchIds != null) 'clinic_branch_ids': clinicBranchIds,
      },
    );
    return AssistantDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<void> deleteAssistant(String id) async {
    await _dio.delete<void>('${ApiPaths.providerAssistants}/$id');
  }
}
