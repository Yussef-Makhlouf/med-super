import 'dart:async';
// `easy_localization` re-exports `intl`, whose `TextDirection` shadows the
// `dart:ui` enum the amount field needs for LTR digits.
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/payments/domain/payment_amount.dart';
import 'package:med_super/core/payments/presentation/widgets/fawry_customer_sheet.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/staggered_reveal.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/appointments/presentation/screens/booking_success_screen.dart';
import 'package:med_super/features/appointments/presentation/screens/fawry_payment_screen.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/wallet/presentation/controllers/wallet_providers.dart';

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
/// (`POST /v1/appointments/hold`), show a countdown, then pay.
///
/// Three payment methods, spanning two endpoints (see
/// [AppointmentPaymentMethod]): pay-at-clinic and wallet both confirm
/// synchronously via `POST /v1/appointments/{holdId}/confirm`, while Fawry
/// goes to `POST /v1/appointments/{holdId}/payments` and leaves the booking
/// pending until the gateway webhook confirms it.
///
/// Reached from `doctor_details_screen`'s "Book Now" button, or from
/// [RescheduleScreen] with [initialHold] already set (skips the auto-hold
/// step).
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
  AppointmentPaymentMethod _method = AppointmentPaymentMethod.payAtClinic;
  late final TextEditingController _amountController;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: PaymentAmount.fromNum(widget.request.consultationFee),
    );
    final initial = widget.initialHold;
    if (initial != null) {
      _hold = initial;
      _setAmountText(
        PaymentAmount.fromNum(
          initial.fullAmount ?? widget.request.consultationFee,
        ),
      );
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
    _amountController.dispose();
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
        _setAmountText(
          PaymentAmount.fromNum(
            hold.fullAmount ?? widget.request.consultationFee,
          ),
        );
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

  Future<void> _pay() async {
    final hold = _hold;
    if (hold == null) return;
    if (!_validateAmountForSubmit()) return;
    if (_method.isSynchronous) {
      await _confirm(hold);
    } else {
      await _payWithFawry(hold);
    }
  }

  /// Server-side minimum for a partial amount, from the hold response
  /// (`minPaymentAmount`). `null` = the policy isn't configured (or this is a
  /// reschedule hold), so only a full payment is offered.
  num? get _minAmount => _hold?.minPaymentAmount;

  /// Once the server creates a hold, its fee and currency are authoritative.
  /// Fall back to the doctor card only while a hold is loading or for legacy
  /// reschedule responses that do not carry payment fields.
  num get _fee => _hold?.fullAmount ?? widget.request.consultationFee;
  String get _currency => _hold?.currency ?? widget.request.currency;

  /// Preserve a valid caret position whenever the fee is copied into the
  /// editable amount field programmatically.
  void _setAmountText(String value) {
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  /// A partial amount is only offered when the method takes one and the
  /// server gave a minimum below the fee (a fee ≤ the minimum can only be
  /// paid in full anyway).
  bool get _partialAllowed {
    final min = _minAmount;
    return _method.supportsPartialPayment &&
        min != null &&
        min < _fee;
  }

  /// Keep the amount visible for wallet and Fawry even when the server
  /// disables partial payments; in that case it displays the full fee only.
  bool get _showPaymentAmount => _method.supportsPartialPayment;

  /// Wallet with less than the fee: start the field at what the wallet can
  /// actually cover instead of a full fee that would fail validation.
  void _onMethodChanged(AppointmentPaymentMethod method) {
    setState(() {
      _method = method;
      _amountError = null;
    });
    if (method.supportsPartialPayment &&
        _amountController.text.trim().isEmpty) {
      _setAmountText(PaymentAmount.fromNum(_fee));
    }
    if (method != AppointmentPaymentMethod.wallet || !_partialAllowed) return;
    final available = ref
        .read(walletBalanceProvider)
        .asData
        ?.value
        .availableBalance;
    if (available == null || available >= _fee) {
      return;
    }
    // Floor to the cent so rounding never proposes more than the balance.
    _setAmountText(
      PaymentAmount.fromNum((available * 100).floor() / 100),
    );
  }

  /// Client-side checks the server will also run: numeric, ≤ 2 decimals,
  /// greater than zero, not below the server minimum, not above the
  /// displayed fee, and (wallet) not above the available balance. The
  /// server re-validates everything; its 422 still lands on the field.
  bool _validateAmountForSubmit() {
    if (!_partialAllowed) {
      setState(() => _amountError = null);
      return true;
    }
    final parsed = PaymentAmount.tryParse(_amountController.text);
    if (parsed == null) {
      setState(() => _amountError = 'appointments.payment_amount_invalid'.tr());
      return false;
    }
    final amount = num.parse(parsed);
    final min = _minAmount!;
    if (amount < min) {
      setState(
        () => _amountError = 'appointments.payment_amount_below_minimum'.tr(
          namedArgs: {'min': PaymentAmount.fromNum(min)},
        ),
      );
      return false;
    }
    if (amount > _fee) {
      setState(
        () => _amountError = 'appointments.payment_amount_exceeds_fee'.tr(
          namedArgs: {'fee': PaymentAmount.fromNum(_fee)},
        ),
      );
      return false;
    }
    if (_method == AppointmentPaymentMethod.wallet) {
      final available = ref
          .read(walletBalanceProvider)
          .asData
          ?.value
          .availableBalance;
      if (available != null && amount > available) {
        setState(
          () => _amountError = 'appointments.wallet_insufficient_for_amount'.tr(
            namedArgs: {'balance': available.toStringAsFixed(2)},
          ),
        );
        return false;
      }
    }
    setState(() => _amountError = null);
    return true;
  }

  /// Omit `paymentAmount` when paying the full displayed fee so this path
  /// stays identical to the pre-partial-payment client (full payments never
  /// need the `MIN_APPOINTMENT_PAYMENT` policy).
  String? _paymentAmountForRequest() {
    if (!_partialAllowed) return null;
    final parsed = PaymentAmount.tryParse(_amountController.text);
    if (parsed == null) return null;
    if (num.parse(parsed) == _fee) return null;
    return parsed;
  }

  String? _displayedPayAmount() {
    if (!_partialAllowed) {
      return PaymentAmount.fromNum(_fee);
    }
    return PaymentAmount.tryParse(_amountController.text);
  }

  void _applyAmountFailure(Failure failure) {
    // Partial payment is unavailable and the visible amount is read-only —
    // surface an inline snackbar rather than attaching an unusable field
    // error. The hold is still valid: the server rolls back without consuming it.
    if (!_partialAllowed) {
      setState(() {
        _stage = _Stage.held;
        _failure = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      return;
    }
    final message = switch (failure) {
      ValidationFailure(:final code, :final fieldErrors) =>
        _amountMessageFor(code, fieldErrors) ?? failureMessage(failure),
      _ => failureMessage(failure),
    };
    setState(() {
      _stage = _Stage.held;
      _failure = null;
      _amountError = message;
    });
  }

  String? _amountMessageFor(String? code, Map<String, String> fieldErrors) {
    final min = fieldErrors['minAmount'];
    if (code == 'PAYMENT_AMOUNT_BELOW_MINIMUM' && min != null) {
      return 'appointments.payment_amount_below_minimum'.tr(
        namedArgs: {'min': min},
      );
    }
    final fee = fieldErrors['fullAmount'];
    if (code == 'PAYMENT_AMOUNT_EXCEEDS_FEE' && fee != null) {
      return 'appointments.payment_amount_exceeds_fee'.tr(
        namedArgs: {'fee': fee},
      );
    }
    return null;
  }

  bool _isAmountFailure(Failure failure) => switch (failure) {
    ValidationFailure(:final code) => _isAmountCode(code),
    ServerFailure(:final code) => _isAmountCode(code),
    _ => false,
  };

  bool _isAmountCode(String? code) => switch (code) {
    'PAYMENT_AMOUNT_BELOW_MINIMUM' ||
    'PAYMENT_AMOUNT_EXCEEDS_FEE' ||
    'PAYMENT_AMOUNT_INVALID' ||
    'PAYMENT_AMOUNT_NOT_SUPPORTED' ||
    'INSUFFICIENT_WALLET_BALANCE' ||
    'MIN_APPOINTMENT_PAYMENT_NOT_CONFIGURED' => true,
    _ => false,
  };

  /// Fawry never produces a confirmed appointment here — the hold is
  /// extended and the patient leaves with a reference code, so this path
  /// deliberately doesn't set [_confirmed] or route to the success screen.
  Future<void> _payWithFawry(AppointmentHold hold) async {
    final session = ref.read(sessionControllerProvider).asData?.value;
    final customer = await showFawryCustomerSheet(
      context,
      initialPhone: session?.user.phone,
    );
    if (customer == null || !mounted) return;

    setState(() => _stage = _Stage.confirming);
    final result = await ref
        .read(initiateOnlinePaymentUseCaseProvider)
        .call(
          hold.holdId,
          method: _method,
          customer: customer,
          paymentAmount: _paymentAmountForRequest(),
        );
    if (!mounted) return;

    result.when(
      ok: (initiation) {
        _ticker?.cancel();
        // The hold now lives on the server for Fawry's own 15-minute window
        // and this screen is done with it, so skip dispose()'s
        // abandoned-hold refresh bump.
        _confirmed = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // The server echoes what Fawry will actually charge — on a retry
            // that's the first attempt's amount, not what was sent now.
            builder: (_) => FawryPaymentScreen(
              initiation: initiation,
              paidAmount:
                  initiation.amount ??
                  _displayedPayAmount() ??
                  PaymentAmount.fromNum(_fee),
              currency: initiation.currency ?? _currency,
            ),
          ),
        );
      },
      err: (failure) {
        if (_isAmountFailure(failure)) {
          _applyAmountFailure(failure);
          return;
        }
        setState(() {
          _stage = _Stage.error;
          _failure = failure;
        });
      },
    );
  }

  Future<void> _confirm(AppointmentHold hold) async {
    setState(() => _stage = _Stage.confirming);
    final result = await ref
        .read(confirmAppointmentUseCaseProvider)
        .call(
          hold.holdId,
          paymentMethod: _method,
          paymentAmount: _paymentAmountForRequest(),
        );
    if (!mounted) return;

    result.when(
      ok: (confirmed) {
        _confirmed = true;
        ref.read(myAppointmentsRefreshProvider.notifier).state++;
        if (_method == AppointmentPaymentMethod.wallet) {
          // The balance was just debited server-side
          // (`CaptureInternalWalletPaymentUseCase`) and a ledger row written.
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
          ref.invalidate(walletTransactionHistoryProvider);
          ref.invalidate(walletTransactionDetailProvider);
        }
        // `go` (not `pushReplacement`) deliberately clears the whole ad-hoc
        // stack this booking flow built up (home → doctor detail → confirm)
        // rather than just swapping the top page for the success screen —
        // otherwise `doctor_details_screen` stays alive underneath it, and
        // returning to the shell's home tab then re-entering the same
        // doctor can resurface this now-stale success page instead of a
        // fresh detail screen.
        context.go(
          '/patient/home/appointments/success',
          extra: BookingSuccessArgs(request: widget.request, method: _method),
        );
      },
      err: (failure) {
        if (_isAmountFailure(failure)) {
          _applyAmountFailure(failure);
          return;
        }
        setState(() {
          _stage = _Stage.error;
          _failure = failure;
        });
      },
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
                    child: _SummaryCard(
                      request: widget.request,
                      fee: _fee,
                      currency: _currency,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PaymentMethodPicker(
                    selected: _method,
                    fee: _fee,
                    minAmount: _minAmount,
                    enabled: _stage == _Stage.held,
                    onChanged: _onMethodChanged,
                  ),
                  if (_showPaymentAmount) ...[
                    const SizedBox(height: 20),
                    _PaymentAmountField(
                      controller: _amountController,
                      currency: _currency,
                      fee: _fee,
                      minAmount: _partialAllowed ? _minAmount : null,
                      errorText: _amountError,
                      enabled: _stage == _Stage.held,
                      partialAllowed: _partialAllowed,
                      onChanged: (_) => setState(() => _amountError = null),
                      onPayFull: () {
                        _setAmountText(PaymentAmount.fromNum(_fee));
                        setState(() => _amountError = null);
                      },
                    ),
                  ],
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
              onConfirm: _pay,
              method: _method,
              payAmountLabel: _displayedPayAmount(),
              currency: _currency,
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
  const _SummaryCard({
    required this.request,
    required this.fee,
    required this.currency,
  });

  final BookingRequest request;
  final num fee;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final formattedFee = PaymentAmount.fromNum(fee);
    final feeLabel = currency == 'EGP' ? '$formattedFee ج.م' : '$formattedFee $currency';
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
          _InfoRow(icon: Icons.access_time_outlined, label: request.timeLabel),
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

/// Pay-at-clinic / wallet / Fawry. The wallet tile reads the real balance
/// (`GET /v1/wallet`) and is locked only when the balance is zero — a
/// partial `paymentAmount` can cover a fee the wallet couldn't pay in full.
/// A confirm that still overshoots the balance is rejected with
/// `INSUFFICIENT_WALLET_BALANCE` *after* the hold was already spent, so the
/// amount field also checks before submit.
class _PaymentMethodPicker extends ConsumerWidget {
  const _PaymentMethodPicker({
    required this.selected,
    required this.fee,
    required this.enabled,
    required this.onChanged,
    this.minAmount,
  });

  final AppointmentPaymentMethod selected;
  final num fee;
  final bool enabled;
  final ValueChanged<AppointmentPaymentMethod> onChanged;

  /// Server minimum for a partial payment; `null` = full payment only.
  final num? minAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final available = balance.asData?.value.availableBalance;
    // The least the wallet must hold: the minimum when a partial amount is
    // allowed, otherwise the whole fee.
    final min = minAmount;
    final walletFloor = min != null && min < fee ? min : fee;
    final canUseWallet = available != null && available >= walletFloor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'appointments.payment_method'.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(height: 10),
        _MethodTile(
          method: AppointmentPaymentMethod.payAtClinic,
          selected: selected,
          enabled: enabled,
          icon: Icons.storefront_outlined,
          title: 'appointments.pay_at_clinic'.tr(),
          subtitle: 'appointments.pay_at_clinic_hint'.tr(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        _MethodTile(
          method: AppointmentPaymentMethod.wallet,
          selected: selected,
          enabled: enabled && canUseWallet,
          icon: Icons.account_balance_wallet_outlined,
          title: 'appointments.pay_with_wallet'.tr(),
          subtitle: switch (available) {
            null => 'appointments.wallet_balance_unavailable'.tr(),
            final b when b <= 0 => 'appointments.wallet_empty'.tr(),
            final b when b < walletFloor =>
              'appointments.wallet_insufficient'.tr(
                namedArgs: {'balance': b.toStringAsFixed(2)},
              ),
            final b when b < fee => 'appointments.wallet_partial_ok'.tr(
              namedArgs: {'balance': b.toStringAsFixed(2)},
            ),
            final b => 'appointments.wallet_balance'.tr(
              namedArgs: {'balance': b.toStringAsFixed(2)},
            ),
          },
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        _MethodTile(
          method: AppointmentPaymentMethod.fawry,
          selected: selected,
          enabled: enabled,
          icon: Icons.receipt_long_outlined,
          title: 'appointments.pay_with_fawry'.tr(),
          subtitle: 'appointments.pay_with_fawry_hint'.tr(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final AppointmentPaymentMethod method;
  final AppointmentPaymentMethod selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<AppointmentPaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == method;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: isSelected
            ? AppPalette.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: enabled ? () => onChanged(method) : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isSelected ? AppPalette.primary : AppPalette.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppPalette.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<AppointmentPaymentMethod>(
                  value: method,
                  groupValue: selected,
                  activeColor: AppPalette.primary,
                  onChanged: enabled
                      ? (value) {
                          if (value != null) onChanged(value);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentAmountField extends StatelessWidget {
  const _PaymentAmountField({
    required this.controller,
    required this.currency,
    required this.fee,
    required this.minAmount,
    required this.enabled,
    required this.partialAllowed,
    required this.onChanged,
    required this.onPayFull,
    this.errorText,
  });

  final TextEditingController controller;
  final String currency;
  final num fee;
  final num? minAmount;
  final bool enabled;
  final bool partialAllowed;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onPayFull;

  @override
  Widget build(BuildContext context) {
    final feeLabel = currency == 'EGP'
        ? '${PaymentAmount.fromNum(fee)} ج.م'
        : '${PaymentAmount.fromNum(fee)} $currency';
    final minLabel = minAmount == null
        ? null
        : currency == 'EGP'
        ? '${PaymentAmount.fromNum(minAmount!)} ج.م'
        : '${PaymentAmount.fromNum(minAmount!)} $currency';
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'appointments.payment_amount'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            partialAllowed
                ? 'appointments.payment_amount_hint'.tr(
                    namedArgs: {'min': minLabel!},
                  )
                : 'appointments.full_payment_only_hint'.tr(),
            style: const TextStyle(fontSize: 12, color: AppPalette.inkMuted),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppPalette.primarySoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'appointments.total_fee_label'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    feeLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.primary,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'appointments.payment_amount_label'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 8),
            decoration: BoxDecoration(
              color: enabled ? AppPalette.surface : AppPalette.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: errorText == null ? AppPalette.border : AppPalette.error,
                width: errorText == null ? 1 : 1.5,
              ),
            ),
            child: Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    readOnly: !partialAllowed,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    textDirection: ui.TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.ink,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                    maxLength: 12,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: PaymentAmount.fromNum(fee),
                      hintStyle: const TextStyle(
                        color: AppPalette.inkFaint,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    currency == 'EGP' ? 'ج.م' : currency,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.error,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (partialAllowed)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: enabled ? onPayFull : null,
                child: Text(
                  'appointments.pay_full_fee'.tr(namedArgs: {'fee': feeLabel}),
                ),
              ),
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
    required this.method,
    required this.payAmountLabel,
    required this.currency,
  });

  final _Stage stage;
  final VoidCallback onConfirm;
  final AppointmentPaymentMethod method;
  final String? payAmountLabel;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final canConfirm = stage == _Stage.held && payAmountLabel != null;
    final isBusy = stage == _Stage.holding || stage == _Stage.confirming;
    final label = payAmountLabel == null
        ? 'appointments.enter_payment_amount'.tr()
        : _labelForAmount(payAmountLabel!, currency, method);
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
                    label,
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

  String _labelForAmount(
    String amount,
    String currency,
    AppointmentPaymentMethod method,
  ) {
    final amountSuffix = currency == 'EGP' ? '$amount ج.م' : '$amount $currency';
    return method.isSynchronous
        ? 'appointments.confirm_booking_with_amount'.tr(
            namedArgs: {'amount': amountSuffix},
          )
        : 'appointments.continue_to_payment_with_amount'.tr(
            namedArgs: {'amount': amountSuffix},
          );
  }
}
