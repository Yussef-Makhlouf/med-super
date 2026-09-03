import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_status_providers.dart';

/// Shown right after a doctor submits their registration, replacing the old
/// unconditional "success" screen that let anyone straight into
/// `/provider/home` the moment they hit submit — before this, nothing ever
/// distinguished "I applied" from "an Admin actually approved me," since
/// `SettingsKeys.providerRegistrationSubmitted` only ever meant the former.
///
/// This screen is the one real check: it fetches
/// `GET /v1/provider/registration/status` on load and via pull-to-refresh
/// (there is no push/webhook path — the applicant must pull to re-check).
/// While still PENDING, there is deliberately no way out except signing
/// out — no back button, no "go home" — since `/provider/home` isn't a
/// real destination yet (the role membership stays PATIENT until verified,
/// see `app_router.dart`'s redirect logic).
///
/// Once VERIFIED, the CTA is "log in again," not "go home": an access token
/// issued before Admin verification still carries the old PATIENT role, and
/// nothing refreshes it in place — `VerifyDoctorUseCase` (backend) grants
/// the DOCTOR role_membership, but the *current* token is unaffected. Only
/// a fresh login (which re-resolves the active role, now DOCTOR — see
/// `RoleMembershipRepository.findActiveByUser`'s most-recent-first
/// ordering) actually picks it up. A "go home" button here would otherwise
/// bounce forever between this screen and `/patient/home`.
class DoctorRegistrationPendingScreen extends ConsumerWidget {
  const DoctorRegistrationPendingScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go('/account-login');
  }

  Future<void> _logoutAndSignInAgain(BuildContext context, WidgetRef ref) =>
      _logout(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(doctorRegistrationStatusProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Explicit fallback for pull-to-refresh: `RefreshIndicator`
            // relies on a touch-drag overscroll gesture, which a mouse drag
            // on Flutter Web frequently doesn't trigger at all — this button
            // works identically on every platform/input method.
            IconButton(
              tooltip: 'provider_registration.review.refresh_tooltip'.tr(),
              onPressed: () =>
                  ref.invalidate(doctorRegistrationStatusProvider),
              icon: const Icon(Icons.refresh, color: Color(0xFF8A94A6)),
            ),
            IconButton(
              tooltip: 'provider_registration.review.logout_tooltip'.tr(),
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF8A94A6)),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(doctorRegistrationStatusProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: statusAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => _StatusMessage(
                        icon: Icons.error_outline,
                        color: AppColors.errorRed,
                        title: 'errors.unexpected'.tr(),
                        message: 'provider_registration.review.status_check_error'
                            .tr(),
                      ),
                      data: (status) => switch (status) {
                        DoctorRegistrationStatus.verified => _StatusMessage(
                          icon: Icons.check_circle,
                          color: AppColors.providerPrimary,
                          title: 'provider_registration.review.verified_title'
                              .tr(),
                          message:
                              'provider_registration.review.verified_message'
                                  .tr(),
                          primaryActionLabel:
                              'provider_registration.review.sign_in_again_cta'
                                  .tr(),
                          onPrimaryAction: () =>
                              _logoutAndSignInAgain(context, ref),
                        ),
                        // Distinct copy from PENDING — a suspended/rejected
                        // applicant must be told plainly, not left reading
                        // "under review" forever with no way to know their
                        // real status. Still no primary action besides
                        // signing out (the app-bar icon): there is nothing
                        // else for a rejected applicant to do here.
                        DoctorRegistrationStatus.suspended => _StatusMessage(
                          icon: Icons.cancel_outlined,
                          color: AppColors.errorRed,
                          title:
                              'provider_registration.review.suspended_title'
                                  .tr(),
                          message:
                              'provider_registration.review.suspended_message'
                                  .tr(),
                        ),
                        // `null` (never actually self-registered) is treated
                        // the same as PENDING here rather than as an error —
                        // this screen is only ever reached via
                        // `providerRegistrationSubmitted` being true, so a
                        // `null` here would mean that flag and the backend
                        // disagree, which pull-to-refresh naturally recovers
                        // from once the backend catches up.
                        DoctorRegistrationStatus.pending ||
                        null => _StatusMessage(
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.providerPrimary,
                          title:
                              'provider_registration.review.pending_title'
                                  .tr(),
                          message:
                              'provider_registration.review.pending_message'
                                  .tr(),
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
  }) : assert(
         (primaryActionLabel == null) == (onPrimaryAction == null),
         'primaryActionLabel and onPrimaryAction must both be set or both be omitted',
       );

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: color, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (primaryActionLabel != null) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(primaryActionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
