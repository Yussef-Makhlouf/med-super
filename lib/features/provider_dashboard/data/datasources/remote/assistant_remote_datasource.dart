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
  });

  /// PATCH /v1/provider/assistants/:id — update display name and/or status.
  Future<AssistantDto> updateAssistant({
    required String id,
    String? displayName,
    String? status,
    String? password,
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
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.providerAssistants,
      data: {'phone': phone, 'display_name': displayName},
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
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.providerAssistants}/$id',
      data: {
        if (displayName != null) 'display_name': displayName,
        if (status != null) 'status': status,
        if (password != null) 'password': password,
      },
    );
    return AssistantDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<void> deleteAssistant(String id) async {
    await _dio.delete<void>('${ApiPaths.providerAssistants}/$id');
  }
}
