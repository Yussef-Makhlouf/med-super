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
  Future<Result<AuthTokens>> setPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final tokens = await _remote.setPassword(phone: phone, password: password);
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
  Future<Result<User>> updateProfile({required String displayName}) async {
    try {
      final dto = await _remote.updateProfile(displayName: displayName);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Always clear local session even if remote logout fails.
    }
    await _storage.clearTokens();
    return const Result.ok(null);
  }
}
