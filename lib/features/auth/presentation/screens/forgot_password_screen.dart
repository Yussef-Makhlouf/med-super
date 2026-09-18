import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/auth_hero_illustration.dart';
import 'package:med_super/core/widgets/auth_phone_field.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';

/// Forgot-password entry screen — phone number only. Reached only from
/// [AccountLoginScreen] (the phone+password login screen), since forgot
/// password only makes sense for someone who already set a password.
/// Visually mirrors the hero-illustration + labeled-field layout used by
/// `login_screen.dart` / `verify_otp_screen.dart`, but as a pushed screen
/// with a back button rather than the initial bottom-sheet screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sending) return;

    final phone = normalizeEgyptPhone(_phoneController.text);
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .forgotPassword(phone: phone);

      if (!mounted) return;

      switch (result) {
        case Ok(:final value):
          context.push(
            '/verify-reset-code',
            extra: {'phone': phone, 'requestId': value.requestId},
          );
        case Err(:final failure):
          final text = authFailureMessage(failure);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const SizedBox(
                        height: 180,
                        child: AuthBlobHeroIllustration(
                          icon: SolarIconsBold.lockPassword,
                          tileSize: 96,
                          iconSize: 52,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'auth.forgot_password_title'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.forgot_password_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'auth.phone_label'.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AuthPhoneField(
                        controller: _phoneController,
                        validator: (_) {
                          final raw = _phoneController.text;
                          if (raw.trim().isEmpty) {
                            return 'auth.phone_required'.tr();
                          }
                          if (!isValidEgyptPhone(raw)) {
                            return 'auth.phone_invalid'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: brandBlue.withValues(
                              alpha: 0.5,
                            ),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'auth.forgot_password_cta'.tr(),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'auth.change_phone'.tr(),
                            style: textTheme.titleSmall?.copyWith(
                              color: brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

