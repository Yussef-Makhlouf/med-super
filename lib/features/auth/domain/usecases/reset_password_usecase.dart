import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  /// Resets the password for the phone tied to [requestId] (created by
  /// [ForgotPasswordUseCase]) once [code] is verified. The real endpoint
  /// returns no tokens, so this does not log the user in — the caller must
  /// route back to the phone+password login screen afterward.
  Future<Result<void>> call({
    required String requestId,
    required String code,
    required String newPassword,
  }) => _repository.resetPassword(
    requestId: requestId,
    code: code,
    newPassword: newPassword,
  );
}
