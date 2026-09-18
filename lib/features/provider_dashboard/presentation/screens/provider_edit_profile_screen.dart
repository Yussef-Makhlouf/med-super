import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/avatar_image.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import '../controllers/provider_dashboard_providers.dart';

/// A doctor's own self-edit is deliberately narrow: `PATCH /v1/doctors/me`
/// (`clinic-reservations` File 12 Part 45) only accepts
/// `bio`/`degree`/`experienceYears` — `name` lives on `User`, not `Doctor`
/// (edited via the shared `PATCH /v1/auth/me`, same call the patient side
/// uses), and `specialty`/`licenseNumber` are Admin-only. This screen shows
/// name/specialty/license read-only for a doctor and only submits the
/// three real fields; an assistant's own name (a `CLINIC_STAFF` `User`, no
/// `Doctor` row at all) goes through that same shared `/v1/auth/me` call
/// instead of the doctor-specific one.
class ProviderEditProfileScreen extends ConsumerStatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  ConsumerState<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState
    extends ConsumerState<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _degreeController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _suppressDirtyTracking = true;
  String? _pickedPhotoDataUri;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_markDirty);
    _emailController = TextEditingController()..addListener(_markDirty);
    _degreeController = TextEditingController()..addListener(_markDirty);
    _experienceController = TextEditingController()..addListener(_markDirty);
    _bioController = TextEditingController()..addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _degreeController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_suppressDirtyTracking || _isDirty) return;
    setState(() => _isDirty = true);
  }

  Future<void> _pickPhoto() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر اختيار الصورة')));
      return;
    }
    final file = result?.files.isEmpty ?? true ? null : result!.files.first;
    final bytes = file?.bytes;
    if (bytes == null) return;

    setState(() {
      _pickedPhotoDataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      _isDirty = true;
    });
  }

  Future<void> _submit({required bool isAssistant}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    if (isAssistant) {
      // Assistants are a CLINIC_STAFF `User` with no `Doctor` row — their
      // own display name is the shared `PATCH /v1/auth/me` this same
      // session provider already uses for the patient side.
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .updateDisplayName(_nameController.text.trim());
      if (!mounted) return;
      setState(() => _isSaving = false);
      switch (result) {
        case Ok():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث البيانات الشخصية بنجاح')),
          );
          Navigator.of(context).pop();
        case Err(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: ${failure.toString()}')),
          );
      }
      return;
    }

    // Email lives on `User`, not `Doctor` — same shared `PATCH /v1/auth/me`
    // call the assistant/patient side uses, sent alongside (not instead of)
    // the doctor-specific update below. `name` is passed through unchanged
    // since it isn't editable on this screen for a doctor.
    final emailResult = await ref
        .read(sessionControllerProvider.notifier)
        .updateDisplayName(
          _nameController.text.trim(),
          email: _emailController.text,
        );
    if (!mounted) return;
    if (emailResult is Err) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${(emailResult as Err).failure.toString()}'),
        ),
      );
      return;
    }

    final useCase = ref.read(updateDoctorAccountUseCaseProvider);
    final result = await useCase.call(
      bio: _bioController.text,
      degree: _degreeController.text,
      yearsOfExperience: int.tryParse(_experienceController.text),
      photoDataUri: _pickedPhotoDataUri,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      ok: (updated) {
        ref.invalidate(doctorAccountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات الشخصية بنجاح')),
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
    final accountAsync = ref.watch(doctorAccountProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final isAssistant = session?.user.isAssistant ?? false;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('المعلومات الشخصية'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: AsyncValueView(
        value: accountAsync,
        onRetry: () => ref.invalidate(doctorAccountProvider),
        data: (account) {
          if (_nameController.text.isEmpty && !_isSaving) {
            _nameController.text = isAssistant
                ? (session?.user.displayName ?? account.name)
                : account.name;
            _emailController.text = account.email ?? '';
            _degreeController.text = account.degree ?? '';
            _experienceController.text = account.yearsOfExperience == null
                ? ''
                : '${account.yearsOfExperience}';
            _bioController.text = account.bio;
            _suppressDirtyTracking = false;
          }

          final ImageProvider? previewImage = _pickedPhotoDataUri != null
              ? resolveAvatarImage(_pickedPhotoDataUri!)
              : account.avatarUrl != null
              ? resolveAvatarImage(account.avatarUrl!)
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo upload is doctor-only — an assistant has no
                  // `Doctor` row for `PATCH /v1/doctors/me` to attach it to.
                  Center(
                    child: GestureDetector(
                      onTap: isAssistant ? null : _pickPhoto,
                      child: Stack(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 96,
                              height: 96,
                              color: AppColors.surfaceCard,
                              alignment: Alignment.center,
                              child: previewImage == null
                                  ? const Icon(
                                      SolarIconsBold.userCircle,
                                      size: 96,
                                      color: AppColors.mutedText,
                                    )
                                  // Top-aligned crop — same fix as
                                  // AvatarCircle, needed here too since a
                                  // freshly picked photo isn't yet a URL.
                                  : Image(
                                      image: previewImage,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    ),
                            ),
                          ),
                          if (!isAssistant)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: brandBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  SolarIconsOutline.camera,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      boxShadow: AppShadows.resting,
                    ),
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'الاسم الكامل',
                          controller: _nameController,
                          // Read-only for a doctor: no self-name-edit
                          // endpoint exists on the Doctor record itself.
                          readOnly: !isAssistant,
                        ),
                        if (!isAssistant) ...[
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'رقم الهاتف',
                            controller: TextEditingController(
                              text: account.phone,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'البريد الإلكتروني',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'التخصص',
                            controller: TextEditingController(
                              text: account.specialty,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'رقم الترخيص',
                            controller: TextEditingController(
                              text: account.licenseNumber,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'المؤهل العلمي',
                            controller: _degreeController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'سنوات الخبرة',
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'نبذة عن الطبيب',
                            controller: _bioController,
                          ),
                        ],
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
                    borderRadius: AppRadii.pill,
                    onPressed: _isDirty
                        ? () => _submit(isAssistant: isAssistant)
                        : null,
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
