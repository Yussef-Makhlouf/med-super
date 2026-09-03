import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<OtpRequestResult>> call({
    required String phone,
    required UserRole role,
  }) =>
      _repository.requestOtp(phone: phone, role: role);
}
