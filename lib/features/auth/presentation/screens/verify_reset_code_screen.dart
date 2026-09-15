import 'dart:async';
import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/auth_hero_illustration.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';

/// Verify-reset-code screen — the forgot-password flow's dedicated OTP-verify
/// step, mirroring `verify_otp_screen.dart`'s 6-digit code boxes / timer /
/// resend UI exactly, but calling the checks-only
/// `POST /v1/auth/password/reset/verify-code` endpoint (no side effects, no
/// tokens issued) instead of `otp/verify`. On success it hands `requestId`
/// and the now-verified `code` forward to [ResetPasswordScreen], whose final
/// `POST /v1/auth/password/reset` call re-sends the code for the backend to
/// re-validate itself.
class VerifyResetCodeScreen extends ConsumerStatefulWidget {
  const VerifyResetCodeScreen({
    required this.phone,
    required this.requestId,
    super.key,
  });

  final String phone;
  final String requestId;

  @override
  ConsumerState<VerifyResetCodeScreen> createState() =>
      _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends ConsumerState<VerifyResetCodeScreen> {
  static const _otpLength = 6;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  late String _requestId;
  int _secondsLeft = 59;
  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _requestId = widget.requestId;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _displayPhone {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 11) {
      final local = digits.length > 11
          ? digits.substring(digits.length - 11)
          : digits;
      return AppFormatters.ltrIsolate(
        '+20 ${local.substring(0, 2)} ${local.substring(2, 5)} '
        '${local.substring(5, 8)} ${local.substring(8)}',
      );
    }
    return AppFormatters.ltrIsolate('+20 ${widget.phone}');
  }

  Future<void> _verify() async {
    if (_code.length != _otpLength) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auth.otp_invalid'.tr())));
      return;
    }

    setState(() => _verifying = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .verifyResetCode(requestId: _requestId, code: _code);

      if (!mounted) return;

      switch (result) {
        case Ok():
          context.push(
            '/reset-password',
            extra: {'requestId': _requestId, 'code': _code},
          );
        case Err(:final failure):
          final text = authFailureMessage(failure);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .forgotPassword(phone: widget.phone);
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          _requestId = value.requestId;
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes.first.requestFocus();
          _startTimer();
        case Err(:final failure):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(authFailureMessage(failure))));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _otpLength || index == 0) {
        for (var i = 0; i < _otpLength; i++) {
          _controllers[i].text = i < digits.length ? digits[i] : '';
        }
        final focusIndex = digits.length.clamp(0, _otpLength - 1);
        _focusNodes[focusIndex].requestFocus();
      } else {
        final digit = digits.isEmpty ? '' : digits[digits.length - 1];
        _controllers[index].text = digit;
        if (digit.isNotEmpty && index < _otpLength - 1) {
          _focusNodes[index + 1].requestFocus();
        }
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0 && !_resending;
    final timerLabel =
        '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:'
        '${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    // Force light theme — matches the rest of the auth flow even when the
    // app is dark.
    return Theme(
      data: AppTheme.light().copyWith(splashFactory: InkRipple.splashFactory),
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: AppPalette.ink,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'app.name'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    AuthShieldHeroIllustration(
                      overlayIcon: SolarIconsBold.lockPassword,
                      tags: const ['OTP', 'VERIFY', 'SECURE', kMockOtpCode],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'auth.verify_reset_code_title'.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auth.verify_reset_code_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppPalette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayPhone,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_otpLength, (index) {
                          return SizedBox(
                            width: 48,
                            height: 56,
                            child: KeyboardListener(
                              focusNode: FocusNode(skipTraversal: true),
                              onKeyEvent: (event) => _onKey(index, event),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.ink,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(_otpLength),
                                ],
                                onChanged: (v) => _onDigitChanged(index, v),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppPalette.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppPalette.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: brandBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: brandBlue.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _verifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'auth.verify'.tr(),
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${'auth.didnt_receive'.tr()} ',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkMuted,
                            ),
                          ),
                          TextSpan(
                            text: timerLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: canResend ? _resend : null,
                      child: Text(
                        'auth.resend_otp'.tr(),
                        style: TextStyle(
                          color: canResend
                              ? brandBlue
                              : AppPalette.inkFaint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'auth.change_phone'.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          color: brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerifyResetCodeHeroIllustration extends StatelessWidget {
  const _VerifyResetCodeHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 120,
              color: brandBlue.withValues(alpha: 0.85),
            ),
            Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: brandBlue.withValues(alpha: 0.95),
            ),
            Positioned(top: 28, left: 36, child: _tag('OTP')),
            Positioned(top: 40, right: 28, child: _tag('VERIFY')),
            Positioned(bottom: 36, left: 28, child: _tag('SECURE')),
          ],
        ),
      ),
    );
  }

  static Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: brandBlue.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: brandBlue.withValues(alpha: 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
  );
}
