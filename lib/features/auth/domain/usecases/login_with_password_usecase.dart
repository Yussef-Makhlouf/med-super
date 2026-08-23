import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class LoginWithPasswordUseCase {
  const LoginWithPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthTokens>> call({
    required String phone,
    required String password,
    required UserRole role,
  }) => _repository.loginWithPassword(
    phone: phone,
    password: password,
    role: role,
  );
}
