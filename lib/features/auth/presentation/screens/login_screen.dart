import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/flavor.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

/// Send-OTP / login screen — matches Figma (light, Arabic RTL).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late UserRole _role;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _role = currentFlavor.isPatient ? UserRole.patient : UserRole.doctor;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sending) return;

    final phone = normalizeSaudiPhone(_phoneController.text);
    setState(() => _sending = true);
    try {
      final result = await ref.read(sessionControllerProvider.notifier).requestOtp(
            phone: phone,
            role: _role,
          );

      if (!mounted) return;

      switch (result) {
        case Ok():
          context.push(
            '/verify-otp',
            extra: {
              'phone': phone,
              'role': _role.name,
            },
          );
        case Err(:final failure):
          final key = failureMessage(failure);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(key.tr())),
          );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme — Figma send-OTP is light even when app is dark.
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            backgroundColor: const Color(0xFFF3F6FB),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: const _LoginHeroIllustration(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black26,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'auth.welcome_back'.tr(),
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A2B4A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth.sign_in_subtitle'.tr(),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8A94A6),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _RoleToggle(
                                value: _role,
                                onChanged: (role) =>
                                    setState(() => _role = role),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'auth.phone_label'.tr(),
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A2B4A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PhoneField(
                                controller: _phoneController,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _sending ? null : _onSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandBlue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        brandBlue.withValues(alpha: 0.5),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
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
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'auth.send_otp'.tr(),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_back,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              if (kDebugMode) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'auth.mock_otp_hint'.tr(),
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF8A94A6),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'common.or'.tr(),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF8A94A6),
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: brandBlue.withValues(alpha: 0.45),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      // Biometric wired in a later sprint.
                                    },
                                    icon: const Icon(
                                      Icons.fingerprint,
                                      color: brandBlue,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleChip(
              label: 'auth.role_doctor'.tr(),
              selected: value == UserRole.doctor,
              onTap: () => onChanged(UserRole.doctor),
            ),
          ),
          Expanded(
            child: _RoleChip(
              label: 'auth.role_patient'.tr(),
              selected: value == UserRole.patient,
              onTap: () => onChanged(UserRole.patient),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? brandBlue : const Color(0xFF8A94A6),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final digits = controller.text.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return 'auth.phone_required'.tr();
        if (digits.length < 9) return 'auth.phone_invalid'.tr();
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
                        LengthLimitingTextInputFormatter(9),
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
                        const Text('🇸🇦', style: TextStyle(fontSize: 18)),
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

class _LoginHeroIllustration extends StatelessWidget {
  const _LoginHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            left: 36,
            child: _blob(36, brandBlue.withValues(alpha: 0.25)),
          ),
          Positioned(
            top: 48,
            right: 40,
            child: _blob(22, brandBlue.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: 56,
            left: 48,
            child: _blob(18, brandBlue.withValues(alpha: 0.2)),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: brandBlue.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
