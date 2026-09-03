import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/data/datasources/remote/assistant_remote_datasource.dart';
import 'package:med_super/features/provider_dashboard/data/repositories/assistant_repository_impl.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/create_assistant_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/delete_assistant_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/get_assistants_usecase.dart';
import 'package:med_super/features/provider_dashboard/domain/usecases/update_assistant_usecase.dart';

/// Plain (non-codegen) Riverpod providers — no build_runner pass needed.
/// Pattern mirrors forgot_password_providers.dart for DI wiring.

// ─── Infrastructure ──────────────────────────────────────────────────────────

final assistantRemoteDatasourceProvider = Provider<AssistantRemoteDatasource>((
  ref,
) {
  return AssistantRemoteDatasourceImpl(ref.watch(dioProvider));
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepositoryImpl(ref.watch(assistantRemoteDatasourceProvider));
});

// ─── Use-case providers ──────────────────────────────────────────────────────

final getAssistantsUseCaseProvider = Provider<GetAssistantsUseCase>((ref) {
  return GetAssistantsUseCase(ref.watch(assistantRepositoryProvider));
});

final createAssistantUseCaseProvider = Provider<CreateAssistantUseCase>((ref) {
  return CreateAssistantUseCase(ref.watch(assistantRepositoryProvider));
});

final updateAssistantUseCaseProvider = Provider<UpdateAssistantUseCase>((ref) {
  return UpdateAssistantUseCase(ref.watch(assistantRepositoryProvider));
});

final deleteAssistantUseCaseProvider = Provider<DeleteAssistantUseCase>((ref) {
  return DeleteAssistantUseCase(ref.watch(assistantRepositoryProvider));
});

// ─── State provider ──────────────────────────────────────────────────────────

/// Async list of assistants.
///
/// Uses `AsyncNotifierProvider.autoDispose(...)` — the builder call syntax
/// required in Riverpod 3 for non-codegen autoDispose async notifiers.
/// The notifier extends [AsyncNotifier] (not a separate AutoDispose class —
/// there is no such class in Riverpod 3; autoDispose is just a flag).
final assistantsProvider =
    AsyncNotifierProvider.autoDispose<AssistantsNotifier, List<Assistant>>(
      AssistantsNotifier.new,
    );

class AssistantsNotifier extends AsyncNotifier<List<Assistant>> {
  @override
  Future<List<Assistant>> build() async {
    final result = await ref.watch(getAssistantsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Create a new assistant. Returns the [ProvisionedAssistant] (with the
  /// one-time generated password) on success, or a [Failure] on error.
  Future<(ProvisionedAssistant?, Failure?)> create({
    required String phone,
    required String displayName,
  }) async {
    final result = await ref
        .read(createAssistantUseCaseProvider)
        .call(phone: phone, displayName: displayName);
    return switch (result) {
      Ok(:final value) => (value, null),
      Err(:final failure) => (null, failure),
    };
  }

  /// Update an existing assistant. Patches the list optimistically on success.
  Future<Failure?> updateAssistant({
    required String id,
    String? displayName,
    AssistantStatus? status,
  }) async {
    final result = await ref
        .read(updateAssistantUseCaseProvider)
        .call(id: id, displayName: displayName, status: status?.apiValue);
    switch (result) {
      case Ok(:final value):
        state = state.whenData(
          (list) => list.map((a) => a.id == id ? value : a).toList(),
        );
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Delete an assistant. Removes it from the list optimistically on success.
  Future<Failure?> delete(String id) async {
    final result = await ref.read(deleteAssistantUseCaseProvider).call(id);
    switch (result) {
      case Ok():
        state = state.whenData(
          (list) => list.where((a) => a.id != id).toList(),
        );
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Prepend a newly created assistant to the list without a full re-fetch.
  void addToList(Assistant assistant) {
    state = state.whenData((list) => [assistant, ...list]);
  }
}
