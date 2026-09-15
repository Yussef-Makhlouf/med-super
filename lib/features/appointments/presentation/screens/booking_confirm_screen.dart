import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/staggered_reveal.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';

enum _Stage { holding, held, confirming, error }

/// Wraps a [BookingRequest] together with an already-created
/// [AppointmentHold] — used when arriving from [RescheduleScreen], where
/// `RescheduleAppointmentUseCase` already produced the hold (File 12 Part
/// 35.10) and this screen just needs to show the countdown and confirm it,
/// not create a fresh one.
class BookingConfirmArgs {
  const BookingConfirmArgs({required this.request, required this.initialHold});

  final BookingRequest request;
  final AppointmentHold initialHold;
}

/// Step 2 (final) of the booking flow: reserve the slot for 5 minutes
/// (`POST /v1/appointments/hold`), show a countdown, then confirm
/// (`POST /v1/appointments/{holdId}/confirm`, pay-at-clinic only — Phase 5
/// Payments doesn't exist yet, File 12 Part 35.4). Reached from
/// `doctor_details_screen`'s "Book Now" button, or from [RescheduleScreen]
/// with [initialHold] already set (skips the auto-hold step).
class BookingConfirmScreen extends ConsumerStatefulWidget {
  const BookingConfirmScreen({
    required this.request,
    this.initialHold,
    super.key,
  });

  final BookingRequest request;
  final AppointmentHold? initialHold;

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  _Stage _stage = _Stage.holding;
  AppointmentHold? _hold;
  Failure? _failure;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHold;
    if (initial != null) {
      _hold = initial;
      _stage = _Stage.held;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startCountdown(initial.expiresAt),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _createHold());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // A hold was created (slot flipped OPEN → HELD server-side) but the
    // user left this screen without confirming — e.g. tapping back on the
    // countdown before it expires. `doctorAvailabilityProvider` watches
    // this same signal (see its doc comment) and would otherwise keep
    // showing the now-HELD slot as available until the backend's own
    // 5-minute/every-minute-cron expiry catches up. The success path
    // already bumps this on confirm, so this only fires for the
    // abandoned-hold case.
    if (_hold != null && !_confirmed) {
      ref.read(myAppointmentsRefreshProvider.notifier).state++;
    }
    super.dispose();
  }

  Future<void> _createHold() async {
    setState(() {
      _stage = _Stage.holding;
      _failure = null;
    });

    final session = ref.read(sessionControllerProvider).asData?.value;
    if (session == null) {
      setState(() {
        _stage = _Stage.error;
        _failure = const Failure.auth();
      });
      return;
    }

    final result = await ref
        .read(createHoldUseCaseProvider)
        .call(
          doctorClinicAffiliationId: widget.request.doctorClinicAffiliationId,
          slotId: widget.request.slotId,
          patientId: session.user.id,
        );
    if (!mounted) return;

    result.when(
      ok: (hold) {
        setState(() {
          _hold = hold;
          _stage = _Stage.held;
        });
        _startCountdown(hold.expiresAt);
      },
      err: (failure) => setState(() {
        _stage = _Stage.error;
        _failure = failure;
      }),
    );
  }

  void _startCountdown(DateTime expiresAt) {
    _ticker?.cancel();
    void tick() {
      final left = expiresAt.difference(DateTime.now().toUtc());
      if (!mounted) return;
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
      if (left.isNegative) {
        _ticker?.cancel();
        setState(() {
          _stage = _Stage.error;
          _failure = const Failure.conflict('appointments.hold_expired');
        });
      }
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _confirm() async {
    final hold = _hold;
    if (hold == null) return;

    setState(() => _stage = _Stage.confirming);
    final result = await ref
        .read(confirmAppointmentUseCaseProvider)
        .call(hold.holdId);
    if (!mounted) return;

    result.when(
      ok: (confirmed) {
        _confirmed = true;
        ref.read(myAppointmentsRefreshProvider.notifier).state++;
        // `go` (not `pushReplacement`) deliberately clears the whole ad-hoc
        // stack this booking flow built up (home → doctor detail → confirm)
        // rather than just swapping the top page for the success screen —
        // otherwise `doctor_details_screen` stays alive underneath it, and
        // returning to the shell's home tab then re-entering the same
        // doctor can resurface this now-stale success page instead of a
        // fresh detail screen.
        context.go(
          '/patient/home/appointments/success',
          extra: widget.request,
        );
      },
      err: (failure) => setState(() {
        _stage = _Stage.error;
        _failure = failure;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  StaggeredReveal(
                    index: 0,
                    child: _SummaryCard(request: widget.request),
                  ),
                  const SizedBox(height: 20),
                  if (_stage == _Stage.held || _stage == _Stage.confirming)
                    _HoldTimer(remaining: _remaining),
                  if (_stage == _Stage.error && _failure != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(
                      message: _failureMessage(_failure!),
                      onRetry: _createHold,
                    ),
                  ],
                ],
              ),
            ),
            _ConfirmBar(
              stage: _stage,
              onConfirm: _confirm,
              fee: widget.request.consultationFee,
              currency: widget.request.currency,
            ),
          ],
        ),
      ),
    );
  }

  /// Every branch delegates to the app-wide Arabic mapper
  /// (`core/error/failure_message.dart`). This screen used to switch on the
  /// backend's English sentences (`'This slot is no longer open.'`), which
  /// broke the moment that copy changed — the mapper keys on `error.code`
  /// instead, and falls back to this screen's own booking copy.
  String _failureMessage(Failure failure) =>
      failureMessage(failure, screenFallback: 'errors.server');
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'appointments.confirm_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(SolarIconsOutline.arrowRight),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.request});

  final BookingRequest request;

  @override
  Widget build(BuildContext context) {
    final feeLabel = request.currency == 'EGP'
        ? '${request.consultationFee} ج.م'
        : '${request.consultationFee} ${request.currency}';
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.doctorName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            request.specialty,
            style: const TextStyle(fontSize: 13, color: AppPalette.inkMuted),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppPalette.border),
          const SizedBox(height: 14),
          _InfoRow(
            icon: SolarIconsOutline.calendarMinimalistic,
            label: request.dayLabel,
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: SolarIconsOutline.clockCircle, label: request.timeLabel),
          const SizedBox(height: 8),
          _InfoRow(
            icon: SolarIconsOutline.walletMoney,
            label: 'appointments.pay_at_clinic'.tr(),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppPalette.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'appointments.consultation_fee'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppPalette.inkMuted,
                ),
              ),
              Text(
                feeLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.inkMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppPalette.ink),
        ),
      ],
    );
  }
}

class _HoldTimer extends StatelessWidget {
  const _HoldTimer({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final low = remaining.inSeconds <= 60;
    final color = low ? AppPalette.error : AppPalette.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(SolarIconsOutline.clockCircle, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'appointments.hold_countdown'.tr(args: ['$minutes:$seconds']),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.stage,
    required this.onConfirm,
    required this.fee,
    required this.currency,
  });

  final _Stage stage;
  final VoidCallback onConfirm;
  final int fee;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final canConfirm = stage == _Stage.held;
    final isBusy = stage == _Stage.holding || stage == _Stage.confirming;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canConfirm ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'appointments.confirm_booking'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
