import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class SwitchContextUseCase {
  const SwitchContextUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthTokens>> call(UserRole role) => _repository.switchContext(role);
}
