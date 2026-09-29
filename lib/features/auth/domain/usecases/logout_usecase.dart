import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({String? fcmToken}) =>
      _repository.logout(fcmToken: fcmToken);
}
