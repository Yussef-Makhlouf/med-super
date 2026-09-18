import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthTokens>> call({
    required String requestId,
    required String phone,
    required String code,
    required UserRole role,
  }) => _repository.verifyOtp(
    requestId: requestId,
    phone: phone,
    code: code,
    role: role,
  );
}
