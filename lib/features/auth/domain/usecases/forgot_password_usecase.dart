import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<OtpRequestResult>> call({required String phone}) =>
      _repository.forgotPassword(phone: phone);
}
