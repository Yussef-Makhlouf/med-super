import 'package:med_super/app/flavor.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

/// Dev bypass skips login/OTP. Keep false for the real Sprint 1 auth loop.
const bool kDevBypassAuth = false;

class Session {
  const Session({
    required this.user,
    required this.onboardingComplete,
  });

  final User user;
  final bool onboardingComplete;

  Session copyWith({
    User? user,
    bool? onboardingComplete,
  }) =>
      Session(
        user: user ?? this.user,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}

bool roleMatchesFlavor(UserRole role, Flavor flavor) {
  if (flavor.isPatient) return role == UserRole.patient;
  return role == UserRole.doctor ||
      role == UserRole.clinic ||
      role == UserRole.pharmacy ||
      role == UserRole.lab;
}

/// Formats a Saudi local 9-digit (or longer) number as E.164 `+966…`.
String normalizeSaudiPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('966') && digits.length >= 12) {
    return '+$digits';
  }
  if (digits.startsWith('0') && digits.length >= 10) {
    return '+966${digits.substring(1)}';
  }
  final local = digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  return '+966$local';
}

String failureMessage(Failure failure) => switch (failure) {
      NetworkFailure() => 'errors.network',
      AuthFailure() => 'errors.session_expired',
      ServerFailure(:final code, :final message) => code == 'OTP_INVALID' ||
              code == 'OTP_EXPIRED'
          ? 'auth.otp_wrong'
          : (message ?? 'errors.server'),
      ValidationFailure(:final fieldErrors) => fieldErrors.isEmpty
          ? 'errors.server'
          : fieldErrors.values.first,
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
          phone: '+966500000000',
          roles: [
            currentFlavor.isPatient ? UserRole.patient : UserRole.doctor,
          ],
          activeRole:
              currentFlavor.isPatient ? UserRole.patient : UserRole.doctor,
          displayName: 'Dev User',
        ),
        onboardingComplete: true,
      );
    }

    final storage = ref.watch(secureStorageProvider);
    if (!await storage.hasSession) return null;

    final result = await ref.read(getCurrentUserUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => Session(
          user: value,
          onboardingComplete: _readOnboardingComplete(),
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

  Future<Result<void>> requestOtp({
    required String phone,
    required UserRole role,
  }) async {
    if (!roleMatchesFlavor(role, currentFlavor)) {
      return Result.err(
        Failure.validation({
          'role': 'auth.role_flavor_mismatch',
        }),
      );
    }
    return ref.read(requestOtpUseCaseProvider).call(
          phone: phone,
          role: role,
        );
  }

  Future<Result<Session>> verifyOtp({
    required String phone,
    required String code,
    required UserRole role,
  }) async {
    if (!roleMatchesFlavor(role, currentFlavor)) {
      return Result.err(
        Failure.validation({
          'role': 'auth.role_flavor_mismatch',
        }),
      );
    }

    final tokensResult = await ref.read(verifyOtpUseCaseProvider).call(
          phone: phone,
          code: code,
          role: role,
        );

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
        if (!roleMatchesFlavor(value.activeRole, currentFlavor)) {
          await ref.read(secureStorageProvider).clearTokens();
          return Result.err(
            Failure.validation({
              'role': 'auth.role_flavor_mismatch',
            }),
          );
        }
        final session = Session(
          user: value,
          onboardingComplete: _readOnboardingComplete(),
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
    final session = Session(user: user, onboardingComplete: true);
    state = AsyncData(session);
    return Result.ok(session);
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
