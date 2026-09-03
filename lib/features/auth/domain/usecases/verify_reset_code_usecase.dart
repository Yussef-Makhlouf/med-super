import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

/// Checks-only verification of a forgot-password code — no side effects,
/// no tokens issued. Gates the password-entry step behind a real backend
/// check; the final [ResetPasswordUseCase] call still re-sends (and
/// re-validates) the code, matching the backend's own re-validation.
class VerifyResetCodeUseCase {
  const VerifyResetCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String requestId,
    required String code,
  }) => _repository.verifyResetCode(requestId: requestId, code: code);
}
