import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:med_super/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';
import 'package:med_super/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:med_super/features/auth/domain/usecases/logout_usecase.dart';
import 'package:med_super/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:med_super/features/auth/domain/usecases/verify_otp_usecase.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) =>
    AuthRemoteDatasource(ref.watch(dioProvider));

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  remote: ref.watch(authRemoteDatasourceProvider),
  storage: ref.watch(secureStorageProvider),
);

@riverpod
RequestOtpUseCase requestOtpUseCase(Ref ref) =>
    RequestOtpUseCase(ref.watch(authRepositoryProvider));

@riverpod
VerifyOtpUseCase verifyOtpUseCase(Ref ref) =>
    VerifyOtpUseCase(ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) =>
    GetCurrentUserUseCase(ref.watch(authRepositoryProvider));

@riverpod
LogoutUseCase logoutUseCase(Ref ref) =>
    LogoutUseCase(ref.watch(authRepositoryProvider));
