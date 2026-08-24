import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class SetPasswordUseCase {
  const SetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String password}) =>
      _repository.setPassword(password: password);
}
