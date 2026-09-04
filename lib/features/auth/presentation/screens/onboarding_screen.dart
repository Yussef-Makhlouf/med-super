import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

/// Mandatory profile completion — name and email are both required before
/// a patient can proceed past this screen (no skip path).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .completeOnboarding(
            displayName: _nameController.text,
            email: _emailController.text,
          );
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          context.go(value.user.isPatient ? '/patient/home' : '/provider/home');
        case Err(:final failure):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(authFailureMessage(failure))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionControllerProvider).asData?.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFDCE8FF),
                    child: Icon(Icons.person, color: brandBlue, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'onboarding.title'.tr(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2B4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'onboarding.subtitle'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8A94A6),
                  ),
                ),
                const SizedBox(height: 20),
                if (session != null)
                  Text(
                    AppFormatters.ltrIsolate(session.user.phone),
                    style: textTheme.titleMedium?.copyWith(
                      color: brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'onboarding.name_label'.tr(),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'onboarding.name_required'.tr()
                      : null,
                  decoration: InputDecoration(
                    hintText: 'onboarding.name_hint'.tr(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'onboarding.email_label'.tr(),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty)
                      return 'onboarding.email_required'.tr();
                    if (!_emailPattern.hasMatch(trimmed)) {
                      return 'onboarding.email_invalid'.tr();
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'onboarding.email_hint'.tr(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                        : Text('onboarding.continue'.tr()),
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
