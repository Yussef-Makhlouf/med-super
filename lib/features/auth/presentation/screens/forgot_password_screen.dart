import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

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
          final key = failureMessage(failure);
          final text = key.startsWith('auth.') || key.startsWith('errors.')
              ? key.tr()
              : key;
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
              foregroundColor: const Color(0xFF1A2B4A),
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
                      const _ForgotPasswordHeroIllustration(),
                      const SizedBox(height: 28),
                      Text(
                        'auth.forgot_password_title'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1A2B4A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.forgot_password_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8A94A6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'auth.phone_label'.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A2B4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ForgotPasswordPhoneField(controller: _phoneController),
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

/// Same bordered-container-plus-country-code shape as `login_screen.dart`'s
/// `_PhoneField` / `account_login_screen.dart`'s `_AccountPhoneField`.
class _ForgotPasswordPhoneField extends StatelessWidget {
  const _ForgotPasswordPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final raw = controller.text;
        if (raw.trim().isEmpty) return 'auth.phone_required'.tr();
        if (!isValidEgyptPhone(raw)) return 'auth.phone_invalid'.tr();
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : const Color(0xFFD8DEE8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.start,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: field.didChange,
                      decoration: InputDecoration(
                        hintText: 'auth.phone_hint'.tr(),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFD8DEE8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'auth.country_code'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B4A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🇪🇬', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Same rounded-blob hero-illustration pattern as `login_screen.dart`'s
/// `_LoginHeroIllustration` / `account_login_screen.dart`'s
/// `_AccountLoginHeroIllustration`, but sized for a scrollable page instead
/// of the pinned top-region layout used on the bottom-sheet screens.
class _ForgotPasswordHeroIllustration extends StatelessWidget {
  const _ForgotPasswordHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 24,
              left: 32,
              child: _blob(32, brandBlue.withValues(alpha: 0.25)),
            ),
            Positioned(
              top: 36,
              right: 36,
              child: _blob(20, brandBlue.withValues(alpha: 0.35)),
            ),
            Positioned(
              bottom: 28,
              left: 44,
              child: _blob(16, brandBlue.withValues(alpha: 0.2)),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: brandBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: brandBlue.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
