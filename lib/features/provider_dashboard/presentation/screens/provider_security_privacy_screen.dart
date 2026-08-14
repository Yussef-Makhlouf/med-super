import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import '../controllers/provider_dashboard_providers.dart';

class ProviderSecurityPrivacyScreen extends ConsumerStatefulWidget {
  const ProviderSecurityPrivacyScreen({super.key});

  @override
  ConsumerState<ProviderSecurityPrivacyScreen> createState() =>
      _ProviderSecurityPrivacyScreenState();
}

class _ProviderSecurityPrivacyScreenState
    extends ConsumerState<ProviderSecurityPrivacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_markDirty);
    _newPasswordController.addListener(_markDirty);
    _confirmPasswordController.addListener(_markDirty);
  }

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمات المرور غير متطابقة')));
      return;
    }

    setState(() => _isSaving = true);
    final useCase = ref.read(changePasswordUseCaseProvider);
    final result = await useCase.call(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
        Navigator.of(context).pop();
      },
      err: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${failure.toString()}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('الأمان والخصوصية'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'كلمة المرور الحالية',
                      controller: _currentPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'كلمة المرور الجديدة',
                      controller: _newPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'تأكيد كلمة المرور الجديدة',
                      controller: _confirmPasswordController,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton.filled(
                label: 'تحديث كلمة المرور',
                isLoading: _isSaving,
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                fullWidth: true,
                onPressed: _isDirty ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
