import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required SecureStorageService storage,
  }) : _remote = remote,
       _storage = storage;

  final AuthRemoteDatasource _remote;
  final SecureStorageService _storage;

  @override
  Future<Result<OtpRequestResult>> requestOtp({
    required String phone,
    required UserRole role,
  }) async {
    try {
      final result = await _remote.requestOtp(phone: phone, role: role);
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<AuthTokens>> verifyOtp({
    required String requestId,
    required String phone,
    required String code,
    required UserRole role,
  }) async {
    try {
      final tokens = await _remote.verifyOtp(
        requestId: requestId,
        phone: phone,
        code: code,
        role: role,
      );
      final entity = tokens.toEntity();
      await _storage.saveTokens(
        accessToken: entity.accessToken,
        refreshToken: entity.refreshToken,
      );
      return Result.ok(entity);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> setPassword({required String password}) async {
    try {
      // No tokens come back (204/no body) — the JWT saved during the
      // preceding OTP-verify step is already the session's token, so there's
      // nothing to re-save here.
      await _remote.setPassword(password: password);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<OtpRequestResult>> forgotPassword({
    required String phone,
  }) async {
    try {
      final result = await _remote.forgotPassword(phone: phone);
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> verifyResetCode({
    required String requestId,
    required String code,
  }) async {
    try {
      await _remote.verifyResetCode(requestId: requestId, code: code);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String requestId,
    required String code,
    required String newPassword,
  }) async {
    try {
      // No tokens come back — the caller must send the user back to
      // /account-login to sign in with the new password.
      await _remote.resetPassword(
        requestId: requestId,
        code: code,
        newPassword: newPassword,
      );
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<AuthTokens>> loginWithPassword({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final tokens = await _remote.loginWithPassword(
        phone: phone,
        password: password,
        role: role,
      );
      final entity = tokens.toEntity();
      await _storage.saveTokens(
        accessToken: entity.accessToken,
        refreshToken: entity.refreshToken,
      );
      return Result.ok(entity);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final dto = await _remote.me();
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      final failure = mapDioToFailure(e, st);
      if (failure is AuthFailure) {
        await _storage.clearTokens();
      }
      return Result.err(failure);
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String displayName,
    String? email,
  }) async {
    try {
      final dto = await _remote.updateProfile(
        displayName: displayName,
        email: email,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _storage.refreshToken;
      if (refreshToken != null) {
        await _remote.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // Always clear local session even if remote logout fails.
    }
    await _storage.clearTokens();
    return const Result.ok(null);
  }
}
