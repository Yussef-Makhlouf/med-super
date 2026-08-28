import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/data/datasources/remote/assistant_remote_datasource.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(this._remote);

  final AssistantRemoteDatasource _remote;

  @override
  Future<Result<List<Assistant>>> getAssistants() async {
    try {
      final dtos = await _remote.getAssistants();
      return Result.ok(dtos.map((d) => d.toEntity()).toList());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<ProvisionedAssistant>> createAssistant({
    required String phone,
    required String displayName,
  }) async {
    try {
      final dto = await _remote.createAssistant(
        phone: phone,
        displayName: displayName,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<Assistant>> updateAssistant({
    required String id,
    String? displayName,
    String? status,
  }) async {
    try {
      final dto = await _remote.updateAssistant(
        id: id,
        displayName: displayName,
        status: status,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAssistant(String id) async {
    try {
      await _remote.deleteAssistant(id);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}
