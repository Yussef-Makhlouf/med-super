import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';

abstract class AuthRepository {
  Future<Result<OtpRequestResult>> requestOtp({
    required String phone,
    required UserRole role,
  });

  Future<Result<AuthTokens>> verifyOtp({
    required String phone,
    required String code,
    required UserRole role,
  });

  Future<Result<User>> getCurrentUser();

  Future<Result<User>> updateProfile({required String displayName});

  Future<Result<void>> logout();
}
