import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:med_super/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:med_super/features/auth/domain/usecases/verify_reset_code_usecase.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';

/// Plain (non-codegen) Riverpod providers for the forgot-password flow —
/// deliberately not `@riverpod`, so this addition doesn't require a
/// `build_runner` regeneration pass over `auth_providers.g.dart`. Same
/// pattern as `doctor_availability_providers.dart`.
final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>(
  (ref) => ForgotPasswordUseCase(ref.watch(authRepositoryProvider)),
);

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)),
);

final verifyResetCodeUseCaseProvider = Provider<VerifyResetCodeUseCase>(
  (ref) => VerifyResetCodeUseCase(ref.watch(authRepositoryProvider)),
);
