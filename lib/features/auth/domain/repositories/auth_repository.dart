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
    required String requestId,
    required String phone,
    required String code,
    required UserRole role,
  });

  /// Sets the account's password. Requires the caller to already hold a
  /// valid session (JWT saved from the preceding OTP-verify step) — the real
  /// endpoint returns no body, so this yields no new tokens.
  Future<Result<void>> setPassword({required String password});

  /// Starts a forgot-password flow for an account that already has a
  /// password, sending an OTP to [phone]. Mirrors [requestOtp]'s response
  /// shape but is a distinct endpoint/flow (no role, no signup).
  Future<Result<OtpRequestResult>> forgotPassword({required String phone});

  /// Checks-only verification of a forgot-password [code] against
  /// [requestId] (from [forgotPassword]) — no side effects, no tokens
  /// issued, mirrors what OTP-verify does for a wrong/expired code but
  /// otherwise changes nothing server-side. Lets the UI gate the
  /// password-entry step behind a real backend check before the final
  /// [resetPassword] call, which re-validates the code itself anyway.
  Future<Result<void>> verifyResetCode({
    required String requestId,
    required String code,
  });

  /// Completes the forgot-password flow: re-validates [code] against
  /// [requestId] (from [forgotPassword]) and sets [newPassword]. The real
  /// endpoint returns no tokens, so this does NOT log the user in — the
  /// caller must route back to the phone+password login screen afterward.
  Future<Result<void>> resetPassword({
    required String requestId,
    required String code,
    required String newPassword,
  });

  Future<Result<AuthTokens>> loginWithPassword({
    required String phone,
    required String password,
    required UserRole role,
  });

  Future<Result<User>> getCurrentUser();

  Future<Result<User>> updateProfile({required String displayName});

  Future<Result<void>> logout();
}
