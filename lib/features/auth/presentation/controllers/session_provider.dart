import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/forgot_password_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

/// Dev bypass skips login/OTP. Keep false for the real Sprint 1 auth loop.
const bool kDevBypassAuth = false;

/// Dev convenience: treat every provider session as if registration were
/// already submitted, so a mock doctor login lands straight on
/// `/provider/home` instead of being forced through the 4-step registration
/// wizard on every run. Only takes effect in mock mode (`AppConfig.isMock`)
/// — never against the real backend. Set to `false` to test the actual
/// registration flow again.
const bool kDevSkipProviderRegistrationInMock = true;

class Session {
  const Session({
    required this.user,
    required this.onboardingComplete,
    required this.passwordComplete,
  });

  final User user;
  final bool onboardingComplete;
  final bool passwordComplete;

  Session copyWith({
    User? user,
    bool? onboardingComplete,
    bool? passwordComplete,
  }) => Session(
    user: user ?? this.user,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    passwordComplete: passwordComplete ?? this.passwordComplete,
  );
}

/// Formats an Egyptian local 10-digit (or longer) number as E.164 `+20…`.
String normalizeEgyptPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('20') && digits.length >= 12) {
    return '+$digits';
  }
  if (digits.startsWith('0') && digits.length >= 11) {
    return '+20${digits.substring(1)}';
  }
  final local = digits.length > 10
      ? digits.substring(digits.length - 10)
      : digits;
  return '+20$local';
}

/// True iff [raw] is a valid Egyptian mobile number in any of the accepted
/// forms: 11-digit local (`01XXXXXXXXX`), 10-digit without leading zero, or
/// 12-digit with the `20` country-code prefix.
bool isValidEgyptPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'^01[0125][0-9]{8}$').hasMatch(digits) ||
      RegExp(r'^1[0125][0-9]{8}$').hasMatch(digits) ||
      RegExp(r'^201[0125][0-9]{8}$').hasMatch(digits);
}

String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'errors.network',
  AuthFailure() => 'errors.session_expired',
  ServerFailure(:final code, :final message) =>
    code == 'OTP_INVALID' || code == 'OTP_EXPIRED'
        ? 'auth.otp_wrong'
        : (message ?? 'errors.server'),
  ValidationFailure(:final fieldErrors) =>
    fieldErrors.isEmpty ? 'errors.server' : fieldErrors.values.first,
  ConflictFailure(:final reason) => reason,
  CacheFailure() => 'errors.server',
  UnknownFailure() => 'errors.unexpected',
};

@riverpod
class SessionController extends _$SessionController {
  @override
  Future<Session?> build() async {
    if (kDevBypassAuth) {
      return Session(
        user: User(
          id: 'dev-user',
          phone: '+201000000000',
          roles: [UserRole.patient],
          activeRole: UserRole.patient,
          displayName: 'Dev User',
        ),
        onboardingComplete: true,
        passwordComplete: true,
      );
    }

    final storage = ref.watch(secureStorageProvider);
    if (!await storage.hasSession) return null;

    final result = await ref.read(getCurrentUserUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => Session(
        user: value,
        onboardingComplete: _readOnboardingComplete(),
        passwordComplete: _readPasswordComplete(),
      ),
      Err() => null,
    };
  }

  bool _readOnboardingComplete() {
    final box = ref.read(hiveServiceProvider).settingsBox;
    return box.get(SettingsKeys.onboardingComplete) == 'true';
  }

  Future<void> _writeOnboardingComplete(bool value) async {
    final box = ref.read(hiveServiceProvider).settingsBox;
    await box.put(SettingsKeys.onboardingComplete, '$value');
  }

  bool _readPasswordComplete() {
    final box = ref.read(hiveServiceProvider).settingsBox;
    return box.get(SettingsKeys.passwordComplete) == 'true';
  }

  Future<void> _writePasswordComplete(bool value) async {
    final box = ref.read(hiveServiceProvider).settingsBox;
    await box.put(SettingsKeys.passwordComplete, '$value');
  }

  Future<Result<void>> requestOtp({
    required String phone,
    required UserRole role,
  }) async {
    return ref.read(requestOtpUseCaseProvider).call(phone: phone, role: role);
  }

  Future<Result<Session>> verifyOtp({
    required String requestId,
    required String phone,
    required String code,
    required UserRole role,
  }) async {
    final tokensResult = await ref
        .read(verifyOtpUseCaseProvider)
        .call(requestId: requestId, phone: phone, code: code, role: role);

    switch (tokensResult) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok():
        break;
    }

    final userResult = await ref.read(getCurrentUserUseCaseProvider).call();
    switch (userResult) {
      case Err(:final failure):
        await ref.read(secureStorageProvider).clearTokens();
        return Result.err(failure);
      case Ok(:final value):
        final session = Session(
          user: value,
          onboardingComplete: _readOnboardingComplete(),
          passwordComplete: _readPasswordComplete(),
        );
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  Future<Result<Session>> setPassword(String password) async {
    final current = state.asData?.value;
    if (current == null) {
      return const Result.err(Failure.auth());
    }

    final result = await ref
        .read(setPasswordUseCaseProvider)
        .call(password: password);
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok():
        await _writePasswordComplete(true);
        final session = current.copyWith(passwordComplete: true);
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  /// Starts the forgot-password flow — no session state changes, since the
  /// caller isn't logged in yet at this point.
  Future<Result<OtpRequestResult>> forgotPassword({
    required String phone,
  }) async {
    return ref.read(forgotPasswordUseCaseProvider).call(phone: phone);
  }

  /// Checks-only verification of a forgot-password code — no session state
  /// changes, no side effects server-side, just a pass/fail so the UI can
  /// gate the password-entry step behind a real backend check.
  Future<Result<void>> verifyResetCode({
    required String requestId,
    required String code,
  }) async {
    return ref
        .read(verifyResetCodeUseCaseProvider)
        .call(requestId: requestId, code: code);
  }

  /// Completes the forgot-password flow. Does NOT update session state or
  /// log the user in — the real endpoint returns no tokens, so the caller
  /// must route back to the phone+password login screen on success.
  Future<Result<void>> resetPassword({
    required String requestId,
    required String code,
    required String newPassword,
  }) async {
    return ref
        .read(resetPasswordUseCaseProvider)
        .call(requestId: requestId, code: code, newPassword: newPassword);
  }

  Future<Result<Session>> loginWithPassword({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final tokensResult = await ref
        .read(loginWithPasswordUseCaseProvider)
        .call(phone: phone, password: password, role: role);

    switch (tokensResult) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok():
        break;
    }

    final userResult = await ref.read(getCurrentUserUseCaseProvider).call();
    switch (userResult) {
      case Err(:final failure):
        await ref.read(secureStorageProvider).clearTokens();
        return Result.err(failure);
      case Ok(:final value):
        final session = Session(
          user: value,
          onboardingComplete: _readOnboardingComplete(),
          passwordComplete: true,
        );
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  Future<Result<Session>> completeOnboarding({String? displayName}) async {
    final current = state.asData?.value;
    if (current == null) {
      return const Result.err(Failure.auth());
    }

    var user = current.user;
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final result = await ref
          .read(authRepositoryProvider)
          .updateProfile(displayName: name);
      switch (result) {
        case Err(:final failure):
          return Result.err(failure);
        case Ok(:final value):
          user = value;
      }
    }

    await _writeOnboardingComplete(true);
    final session = current.copyWith(user: user, onboardingComplete: true);
    state = AsyncData(session);
    return Result.ok(session);
  }

  /// Persists display name via `PATCH /v1/auth/me` and refreshes session.
  Future<Result<Session>> updateDisplayName(String displayName) async {
    final current = state.asData?.value;
    if (current == null) {
      return const Result.err(Failure.auth());
    }

    final name = displayName.trim();
    if (name.isEmpty) {
      return const Result.err(
        Failure.validation({'display_name': 'profile.full_name_required'}),
      );
    }

    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(displayName: name);
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        final session = current.copyWith(user: value);
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    await _writeOnboardingComplete(false);
    state = const AsyncData(null);
  }
}

/// Whether a valid session exists. Router guard reads this.
@riverpod
Future<bool> hasSession(Ref ref) async {
  final session = await ref.watch(sessionControllerProvider.future);
  return session != null;
}
