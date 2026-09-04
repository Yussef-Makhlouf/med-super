import 'package:easy_localization/easy_localization.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/forgot_password_providers.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_controller.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_list_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:med_super/features/wallet/presentation/controllers/wallet_providers.dart';
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

/// Arabic copy for an auth failure, already translated — callers render it
/// directly.
///
/// This used to return *either* a translation key *or* the backend's raw
/// `message`, leaving every screen to guess which with
/// `key.startsWith('auth.') ? key.tr() : key`. That guess is what let English
/// server text reach the screen. Now the shared mapper
/// (`core/error/failure_message.dart`) resolves `error.code` to Arabic and
/// this only adds the one auth-specific override.
String authFailureMessage(Failure failure) {
  final code = switch (failure) {
    ServerFailure(:final code) => code,
    ConflictFailure(:final code) => code,
    ValidationFailure(:final code) => code,
    _ => null,
  };
  // Mock mode answers `OTP_INVALID`/`OTP_EXPIRED`; the real backend answers
  // `INVALID_CODE`/`CODE_EXPIRED`/`TOO_MANY_ATTEMPTS` (File 10 §2.3). Both
  // mean the same thing to someone staring at an OTP box.
  const otpCodes = {
    'OTP_INVALID',
    'OTP_EXPIRED',
    'INVALID_CODE',
    'CODE_EXPIRED',
  };
  if (code != null && otpCodes.contains(code)) return 'auth.otp_wrong'.tr();

  return failureMessage(failure);
}

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
        onboardingComplete: value.profileComplete || _readOnboardingComplete(),
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
        // Backend bug (tracked separately): `POST /v1/auth/otp/verify`
        // ignores `role` entirely and always creates a PATIENT
        // role_membership, so `value.isPatient` is true here even when the
        // user picked "doctor" on the login screen. Remember that choice
        // locally so the router can route a fresh doctor signup into the
        // provider-registration flow instead of the patient onboarding —
        // without this, choosing "doctor" here was silently discarded.
        if (role == UserRole.doctor) {
          await ref
              .read(hiveServiceProvider)
              .settingsBox
              .put(SettingsKeys.choseDoctorRoleAtSignup, 'true');
        }
        await _claimRegistrationDraft(value.id);
        await _resyncDoctorRegistrationStatus();
        final session = Session(
          user: value,
          onboardingComplete: value.profileComplete || _readOnboardingComplete(),
          passwordComplete: _readPasswordComplete(),
        );
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  /// Discards the in-progress doctor-registration draft if it belongs to a
  /// *different* account, then claims it (or a fresh/no-op one) as this
  /// user's own. Covers the gap `logout()`'s own draft-clear can't: a
  /// previous session that ended without ever calling `logout()` (app
  /// killed or closed mid-registration, a crash) leaves the draft on disk
  /// with no owner recorded — the very next login on this device, by
  /// *any* account, must not inherit that half-filled personal
  /// data/documents. Called from both `verifyOtp` and `loginWithPassword`,
  /// right after the account is confirmed (so `value.id` is known),
  /// before the new `Session` is published.
  Future<void> _claimRegistrationDraft(String userId) async {
    final draftController = ref.read(registrationFormControllerProvider.notifier);
    await draftController.discardIfOwnedByDifferentUser(userId);
    await draftController.stampDraftOwner(userId);
  }

  /// One-time-per-login check against the real backend status
  /// (`GET /v1/provider/registration/status`), so a still-PENDING doctor
  /// who logged out (which deliberately wipes
  /// `SettingsKeys.providerRegistrationSubmitted`, to stop one account's
  /// registration state leaking into the next login on this device) still
  /// lands back on the pending-approval screen after logging back in.
  /// Deliberately NOT called from the router's `redirect` on every
  /// navigation — that would mean every patient, not just doctors, firing a
  /// request per screen change. `404` (never self-registered) always leaves
  /// the flag untouched (a genuine patient). A network/server failure
  /// retries once immediately (covers a transient blip without adding any
  /// retry UI) before also leaving the flag untouched — better to
  /// occasionally miss a real PENDING doctor once in a rare double-failure
  /// than to ever block or fail the login itself over this check.
  Future<void> _resyncDoctorRegistrationStatus() async {
    var result = await ref.read(myDoctorRegistrationStatusUseCaseProvider).call();
    if (result case Err()) {
      result = await ref.read(myDoctorRegistrationStatusUseCaseProvider).call();
    }
    switch (result) {
      case Ok(:final value) when value != null:
        await ref
            .read(hiveServiceProvider)
            .settingsBox
            .put(SettingsKeys.providerRegistrationSubmitted, 'true');
      case Ok():
      case Err():
        break;
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
        await _writePasswordComplete(true);
        await _claimRegistrationDraft(value.id);
        await _resyncDoctorRegistrationStatus();
        final session = Session(
          user: value,
          onboardingComplete: value.profileComplete || _readOnboardingComplete(),
          passwordComplete: true,
        );
        state = AsyncData(session);
        return Result.ok(session);
    }
  }

  Future<Result<Session>> completeOnboarding({
    required String displayName,
    required String email,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      return const Result.err(Failure.auth());
    }

    var user = current.user;
    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(displayName: displayName.trim(), email: email.trim());
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        user = value;
    }

    await _writeOnboardingComplete(true);
    final session = current.copyWith(user: user, onboardingComplete: true);
    state = AsyncData(session);
    return Result.ok(session);
  }

  /// Persists display name (and optionally email) via `PATCH /v1/auth/me`
  /// and refreshes session. `email` is write-only server-side (`GET
  /// /v1/auth/me` does return it as of File 12 Part 45, so it round-trips
  /// back into `session.user.email` after this call) — an empty/unchanged
  /// value is simply omitted from the request.
  Future<Result<Session>> updateDisplayName(
    String displayName, {
    String? email,
  }) async {
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
    final trimmedEmail = email?.trim();

    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          displayName: name,
          email: (trimmedEmail == null || trimmedEmail.isEmpty)
              ? null
              : trimmedEmail,
        );
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
    await _writePasswordComplete(false);
    // Both are Hive-persisted local flags, not Riverpod providers, so they
    // need their own explicit clear here — otherwise a different person
    // signing in afterward on this same device/tab would inherit whatever
    // registration state the previous account left behind (same class of
    // bug `_resetEphemeralFlowState` exists to prevent for provider caches).
    final settingsBox = ref.read(hiveServiceProvider).settingsBox;
    await settingsBox.delete(SettingsKeys.providerRegistrationSubmitted);
    await settingsBox.delete(SettingsKeys.choseDoctorRoleAtSignup);
    // The in-progress doctor-registration draft (name, email, license
    // number, profile photo, uploaded ID/license documents) is also
    // Hive-persisted and its controller is `@Riverpod(keepAlive: true)` —
    // neither is touched by clearing the two flags above. Confirmed live:
    // without this, a different person registering as a doctor on this
    // same device would see the previous applicant's half-filled personal
    // data and documents. `ref.invalidate` forces `build()` to re-run,
    // which re-reads the (now-cleared) Hive box and returns a fresh draft.
    await ref
        .read(hiveServiceProvider)
        .providerRegistrationDraftBox
        .delete(providerRegistrationDraftKey);
    ref.invalidate(registrationFormControllerProvider);
    state = const AsyncData(null);
    _resetEphemeralFlowState();
  }

  /// None of these providers are per-session by construction — they're
  /// plain (non-`autoDispose`) `Notifier`/`FutureProvider`s that live for
  /// the whole app process, so whatever a patient typed/picked mid-flow
  /// (an attached prescription photo, a chosen pharmacy, an in-flight
  /// order submission) — or whatever backend data they already fetched
  /// (their pharmacy orders, appointments, wallet balance/transactions) —
  /// would otherwise still be sitting there for the next person who logs
  /// into this same browser tab/app instance. Confirmed live 2026-09-03:
  /// logging out a patient and signing up as a new one still showed the
  /// previous patient's pharmacy orders, because `pharmacyOrdersProvider`
  /// wasn't in this list. Logout is the one guaranteed "this session is
  /// over" boundary, so it resets every such provider found across the app
  /// (audited repo-wide — `@riverpod` codegen without `keepAlive: true` is
  /// `autoDispose` by default and self-clears once unwatched, so it's only
  /// these hand-written plain providers that need resetting here).
  void _resetEphemeralFlowState() {
    ref.invalidate(uploadedPrescriptionImagesProvider);
    ref.invalidate(selectedDeliveryMethodProvider);
    ref.invalidate(selectedPharmacyProvider);
    ref.invalidate(pharmacySearchQueryProvider);
    ref.invalidate(pharmacySearchProvider);
    ref.invalidate(pharmacyOrderControllerProvider);
    ref.invalidate(prescriptionUploadControllerProvider);
    ref.invalidate(pharmacyOrdersProvider);
    ref.invalidate(pharmacyOrderDetailProvider);
    ref.invalidate(pharmacyOrderApproveControllerProvider);
    ref.invalidate(myAppointmentsProvider);
    ref.invalidate(myAppointmentsRefreshProvider);
    ref.invalidate(walletBalanceProvider);
    ref.invalidate(walletTransactionsProvider);
    ref.invalidate(walletTransactionDetailProvider);
    ref.invalidate(refundStatusProvider);
  }
}

/// Whether a valid session exists. Router guard reads this.
@riverpod
Future<bool> hasSession(Ref ref) async {
  final session = await ref.watch(sessionControllerProvider.future);
  return session != null;
}
