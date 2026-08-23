import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/auth/presentation/utils/auth_validators.dart';

/// Set-password screen — shown after OTP verification, before onboarding/home.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({required this.phone, this.role = 'patient', super.key});

  final String phone;
  final String role;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Rebuild the live requirement chips/strength label on every keystroke.
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
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .setPassword(_passwordController.text);

      if (!mounted) return;

      switch (result) {
        case Ok():
          context.go('/');
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme — matches verify-OTP / Figma light auth flow.
    // splashFactory override avoids Material 3's default InkSparkle, whose
    // fragment shader throws on backends (and the software renderer used
    // under `flutter test`) that don't support its runtime stage data.
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
                      Text(
                        'auth.set_password_title'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1A2B4A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.set_password_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8A94A6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'auth.password_requirements_hint'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8A94A6),
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
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8DEE8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8DEE8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: brandBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PasswordStrengthAndRequirements(
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
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8DEE8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8DEE8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: brandBlue.withValues(
                              alpha: 0.5,
                            ),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'auth.set_password_cta'.tr(),
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

/// Live strength label + requirement chips shown under the password field,
/// updating on every keystroke via [SetPasswordScreen]'s controller listener.
class _PasswordStrengthAndRequirements extends StatelessWidget {
  const _PasswordStrengthAndRequirements({required this.password});

  final String password;

  static const _weakColor = Color(0xFFE0553F);
  static const _mediumColor = Color(0xFFE0A02E);
  static const _strongColor = Color(0xFF1D9A6C);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strength = passwordStrength(password);
    final (strengthLabel, strengthColor) = switch (strength) {
      PasswordStrength.weak => ('auth.password_strength_weak'.tr(), _weakColor),
      PasswordStrength.medium => (
        'auth.password_strength_medium'.tr(),
        _mediumColor,
      ),
      PasswordStrength.strong => (
        'auth.password_strength_strong'.tr(),
        _strongColor,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          Row(
            children: [
              Text(
                strengthLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RequirementChip(
              label: 'auth.requirement_length'.tr(),
              met: passwordHasMinLength(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_uppercase'.tr(),
              met: passwordHasUppercase(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_lowercase'.tr(),
              met: passwordHasLowercase(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_number'.tr(),
              met: passwordHasNumber(password),
            ),
            _RequirementChip(
              label: 'auth.requirement_symbol'.tr(),
              met: passwordHasSymbol(password),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF1D9A6C) : const Color(0xFF8A94A6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: met ? const Color(0xFFE7F6EF) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: met ? const Color(0xFF1D9A6C).withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
