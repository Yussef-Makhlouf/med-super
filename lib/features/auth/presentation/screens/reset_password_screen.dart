import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/auth/presentation/utils/auth_validators.dart';
import 'package:med_super/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:solar_icons/solar_icons.dart';

/// Password-only screen for the forgot-password flow — reached only after
/// [VerifyResetCodeScreen] has already checked the code against the
/// backend. Mirrors `set_password_screen.dart`'s fields/validators/strength
/// chips exactly; the real `POST /v1/auth/password/reset` endpoint still
/// takes `code` alongside `newPassword` (it re-validates the code itself and
/// revokes other sessions), so [code] is carried forward from the previous
/// screen and re-sent here rather than re-entered.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    required this.requestId,
    required this.code,
    super.key,
  });

  final String requestId;
  final String code;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Rebuild the live strength label/requirement chips on every keystroke.
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .resetPassword(
            requestId: widget.requestId,
            code: widget.code,
            newPassword: _passwordController.text,
          );

      if (!mounted) return;

      switch (result) {
        case Ok():
          // Reset does NOT log the user in (no tokens back) — send them to
          // the password-login screen to sign in with the new password.
          context.go(
            '/account-login',
            extra: {'successMessageKey': 'auth.reset_password_success'},
          );
        case Err(:final failure):
          final text = authFailureMessage(failure);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                      Text(
                        'auth.reset_password_title'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.reset_password_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'auth.password_requirements_hint'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(passwordMaxLength),
                        ],
                        onFieldSubmitted: (_) =>
                            _confirmFocusNode.requestFocus(),
                        validator: (value) {
                          final key = validatePassword(value ?? '');
                          return key?.tr();
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'auth.password_label'.tr(),
                          hintText: 'auth.password_hint'.tr(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? SolarIconsOutline.eye
                                  : SolarIconsOutline.eyeClosed,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: brandBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PasswordStrengthIndicator(
                        password: _passwordController.text,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        focusNode: _confirmFocusNode,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(passwordMaxLength),
                        ],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          final key = validatePasswordConfirmation(
                            _passwordController.text,
                            value ?? '',
                          );
                          return key?.tr();
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'auth.confirm_new_password_label'.tr(),
                          hintText: 'auth.confirm_password_hint'.tr(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? SolarIconsOutline.eye
                                  : SolarIconsOutline.eyeClosed,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: brandBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: brandBlue.withValues(
                              alpha: 0.5,
                            ),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'auth.reset_password_cta'.tr(),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
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

