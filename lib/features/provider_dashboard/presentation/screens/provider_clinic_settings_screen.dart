import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import '../../domain/entities/clinic_settings.dart';
import '../controllers/provider_dashboard_providers.dart';

class ProviderClinicSettingsScreen extends ConsumerStatefulWidget {
  const ProviderClinicSettingsScreen({super.key});

  @override
  ConsumerState<ProviderClinicSettingsScreen> createState() =>
      _ProviderClinicSettingsScreenState();
}

class _ProviderClinicSettingsScreenState
    extends ConsumerState<ProviderClinicSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  bool _isSaving = false;
  bool _isDirty = false;
  // True until the initial values are filled in from the loaded settings —
  // suppresses the dirty-tracking listeners during that one-time fill.
  bool _suppressDirtyTracking = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_markDirty);
    _addressController = TextEditingController()..addListener(_markDirty);
    _phoneController = TextEditingController()..addListener(_markDirty);
    _emailController = TextEditingController()..addListener(_markDirty);
    _cityController = TextEditingController()..addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_suppressDirtyTracking || _isDirty) return;
    setState(() => _isDirty = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final useCase = ref.read(updateClinicSettingsUseCaseProvider);
    final result = await useCase.call(
      ClinicSettings(
        clinicName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      ok: (updated) {
        ref.invalidate(clinicSettingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث إعدادات العيادة بنجاح')),
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
    final settingsAsync = ref.watch(clinicSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('إعدادات العيادة'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: AsyncValueView(
        value: settingsAsync,
        onRetry: () => ref.invalidate(clinicSettingsProvider),
        data: (settings) {
          if (_nameController.text.isEmpty && !_isSaving) {
            _nameController.text = settings.clinicName;
            _addressController.text = settings.address;
            _phoneController.text = settings.phone;
            _emailController.text = settings.email;
            _cityController.text = settings.city;
            _suppressDirtyTracking = false;
          }

          return SingleChildScrollView(
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
                      children: [
                        AppTextField(
                          label: 'اسم العيادة / المجمع الطبي',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'المدينة',
                          controller: _cityController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'العنوان التفصيلي',
                          controller: _addressController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'رقم الهاتف للتواصل',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'البريد الإلكتروني للعيادة',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton.filled(
                    label: 'حفظ التغييرات',
                    isLoading: _isSaving,
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    fullWidth: true,
                    onPressed: _isDirty ? _submit : null,
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
