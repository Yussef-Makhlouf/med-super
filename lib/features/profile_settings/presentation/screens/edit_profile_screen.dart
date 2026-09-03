import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

/// Patient edit-profile form — matches Figma (light, Arabic RTL).
///
/// Date of birth, gender, and address were removed 2026-08-31 — none of
/// them has a backing column on the real `User` model (`clinic-reservations`
/// `prisma/schema/identity.prisma`), so they were pure UI with nothing to
/// ever persist to. Only `displayName`/`email` are real, editable fields
/// (`PATCH /v1/auth/me`, `UpdateMeDto`); `phone` stays read-only (no
/// endpoint changes it post-signup).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _saving = false;
  bool _prefilled = false;
  bool _dirty = false;
  String _initialName = '';
  String _initialEmail = '';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_recomputeDirty);
    _emailController.addListener(_recomputeDirty);
  }

  @override
  void dispose() {
    _nameController.removeListener(_recomputeDirty);
    _emailController.removeListener(_recomputeDirty);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _recomputeDirty() {
    final dirty =
        _nameController.text != _initialName ||
        _emailController.text != _initialEmail;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  void _prefillFromSession(Session? session) {
    if (_prefilled || session == null) return;
    final user = session.user;
    _initialName = user.displayName ?? '';
    _initialEmail = user.email ?? '';
    _nameController.text = _initialName;
    _phoneController.text = user.phone;
    _emailController.text = _initialEmail;
    _prefilled = true;
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .updateDisplayName(
            _nameController.text,
            email: _emailController.text,
          );

      if (!mounted) return;

      switch (result) {
        case Ok():
          _initialName = _nameController.text;
          _initialEmail = _emailController.text;
          if (mounted) setState(() => _dirty = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profile.saved'.tr())));
        case Err(:final failure):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failureMessage(failure).tr())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onLogout() async {
    await ref.read(sessionControllerProvider.notifier).logout();
    // '/account-login' (phone+password), not '/login' (OTP first-time
    // signup) — a returning, already-registered patient logging back out
    // belongs on the returning-user screen, matching the router's own
    // `initialLocation`/no-session redirect target.
    if (mounted) context.go('/account-login');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    _prefillFromSession(session);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'profile.edit_title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2B4A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'profile.logout'.tr(),
            onPressed: _onLogout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF8A94A6)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFFDCE8FF),
                      child: Icon(Icons.person, color: brandBlue, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LabeledField(
                            label: 'profile.full_name'.tr(),
                            child: _ProfileTextField(
                              controller: _nameController,
                              hint: 'profile.full_name_hint'.tr(),
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'profile.full_name_required'.tr();
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'profile.mobile'.tr(),
                            child: _ProfileTextField(
                              controller: _phoneController,
                              icon: Icons.smartphone_outlined,
                              keyboardType: TextInputType.phone,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'profile.email'.tr(),
                            child: _ProfileTextField(
                              controller: _emailController,
                              hint: 'profile.email_hint'.tr(),
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) return null;
                                if (!RegExp(
                                  r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(trimmed)) {
                                  return 'profile.email_invalid'.tr();
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_saving || !_dirty) ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: brandBlue.withValues(alpha: 0.5),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // RTL places the first child on the right → icon
                            // sits to the right of the label, matching Figma.
                            const Icon(Icons.save_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'profile.save_changes'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A94A6),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF1A2B4A),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0B8C5),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        // Icons sit on the visual left in the RTL mockup → trailing/suffix.
        suffixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF8A94A6), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
