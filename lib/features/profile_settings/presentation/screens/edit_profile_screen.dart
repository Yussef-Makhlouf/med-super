import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

enum _Gender { male, female }

/// Patient edit-profile form — matches Figma (light, Arabic RTL).
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
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  _Gender _gender = _Gender.male;
  bool _saving = false;
  bool _prefilled = false;

  static final _dobFormat = DateFormat('MM/dd/yyyy');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _prefillFromSession(Session? session) {
    if (_prefilled || session == null) return;
    final user = session.user;
    _nameController.text = user.displayName ?? '';
    _phoneController.text = user.phone;
    _prefilled = true;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: brandBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .updateDisplayName(_nameController.text);

      if (!mounted) return;

      switch (result) {
        case Ok():
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
    if (mounted) context.go('/login');
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
                    const _ProfileAvatar(),
                    const SizedBox(height: 20),
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
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'profile.date_of_birth'.tr(),
                            child: _DobField(
                              value: _dateOfBirth == null
                                  ? null
                                  : _dobFormat.format(_dateOfBirth!),
                              onTap: _pickDateOfBirth,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'profile.gender'.tr(),
                            child: _GenderToggle(
                              value: _gender,
                              onChanged: (g) => setState(() => _gender = g),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'profile.address'.tr(),
                            child: _ProfileTextField(
                              controller: _addressController,
                              hint: 'profile.address_hint'.tr(),
                              icon: Icons.location_on_outlined,
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
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
                  onPressed: _saving ? null : _onSave,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDCE8FF),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: brandBlue,
                ),
              ),
              PositionedDirectional(
                // Mockup places the edit badge on the visual bottom-left.
                end: 0,
                bottom: 0,
                child: Material(
                  color: brandBlue,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('profile.photo_soon'.tr())),
                      );
                    },
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'profile.change_photo'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8A94A6)),
        ),
      ],
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
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      maxLines: maxLines,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMultiline ? 14 : 16,
        ),
        // Icons sit on the visual left in the RTL mockup → trailing/suffix.
        suffixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF8A94A6), size: 22),
        suffixIconConstraints: isMultiline
            ? const BoxConstraints(minWidth: 48, minHeight: 72)
            : null,
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

class _DobField extends StatelessWidget {
  const _DobField({required this.onTap, this.value});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF8A94A6),
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
            ),
          ),
          child: Text(
            hasValue ? value! : 'profile.date_of_birth_hint'.tr(),
            style: TextStyle(
              color: hasValue
                  ? const Color(0xFF1A2B4A)
                  : const Color(0xFFB0B8C5),
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({required this.value, required this.onChanged});

  final _Gender value;
  final ValueChanged<_Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: Row(
        children: [
          // In RTL: Male (ذكر) on the right — first child.
          Expanded(
            child: _GenderChip(
              label: 'profile.gender_male'.tr(),
              selected: value == _Gender.male,
              onTap: () => onChanged(_Gender.male),
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(11),
              ),
            ),
          ),
          Expanded(
            child: _GenderChip(
              label: 'profile.gender_female'.tr(),
              selected: value == _Gender.female,
              onTap: () => onChanged(_Gender.female),
              borderRadius: const BorderRadiusDirectional.horizontal(
                end: Radius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.borderRadius,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brandBlue : Colors.white,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius.resolve(Directionality.of(context)),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF8A94A6),
            ),
          ),
        ),
      ),
    );
  }
}
