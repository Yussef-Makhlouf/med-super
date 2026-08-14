import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/avatar_image.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import '../controllers/provider_dashboard_providers.dart';

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
  late final TextEditingController _specialtyController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  bool _isSaving = false;
  bool _isDirty = false;
  // True until the initial values are filled in from the loaded account —
  // suppresses the dirty-tracking listeners during that one-time fill.
  bool _suppressDirtyTracking = true;

  // Avatar change is staged locally and only persisted on "حفظ التغييرات",
  // per explicit user request — picking/deleting a photo must not save by
  // itself.
  PlatformFile? _pendingAvatarFile;
  Uint8List? _pendingAvatarPreviewBytes;
  bool _avatarRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_markDirty);
    _specialtyController = TextEditingController()..addListener(_markDirty);
    _experienceController = TextEditingController()..addListener(_markDirty);
    _bioController = TextEditingController()..addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_suppressDirtyTracking || _isDirty) return;
    setState(() => _isDirty = true);
  }

  Future<void> _pickAvatar() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح معرض الصور، حاول مرة أخرى')),
      );
      return;
    }

    final files = picked?.files ?? const <PlatformFile>[];
    final file = files.isEmpty ? null : files.first;
    if (file == null || file.bytes == null) return; // user cancelled.

    setState(() {
      _pendingAvatarFile = file;
      _pendingAvatarPreviewBytes = file.bytes;
      _avatarRemoved = false;
      _isDirty = true;
    });
  }

  void _removeAvatar() {
    setState(() {
      _pendingAvatarFile = null;
      _pendingAvatarPreviewBytes = null;
      _avatarRemoved = true;
      _isDirty = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    if (_pendingAvatarFile != null || _avatarRemoved) {
      // Send the actually-picked bytes as a base64 data URI — there's no
      // real backend/storage to host the file, and a fake stock-photo URL
      // would show the same generic image on every upload regardless of
      // what was picked, which reads as "the old photo didn't change".
      final avatarPayload = _pendingAvatarPreviewBytes != null
          ? 'data:image/jpeg;base64,${base64Encode(_pendingAvatarPreviewBytes!)}'
          : '';
      final avatarUseCase = ref.read(uploadAvatarUseCaseProvider);
      final avatarResult = await avatarUseCase.call(avatarPayload);

      if (!mounted) return;
      if (avatarResult.isErr) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${avatarResult.failureOrNull.toString()}'),
          ),
        );
        return;
      }
    }

    final useCase = ref.read(updateDoctorAccountUseCaseProvider);
    final result = await useCase.call(
      name: _nameController.text.trim(),
      specialty: _specialtyController.text.trim(),
      yearsOfExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
      bio: _bioController.text.trim(),
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
            _nameController.text = account.name;
            _specialtyController.text = account.specialty;
            _experienceController.text = '${account.yearsOfExperience}';
            _bioController.text = account.bio;
            _suppressDirtyTracking = false;
          }

          // Preview precedence: freshly-picked photo > pending removal
          // (show placeholder) > the account's currently saved photo.
          final ImageProvider? previewImage = _pendingAvatarPreviewBytes != null
              ? MemoryImage(_pendingAvatarPreviewBytes!)
              : (!_avatarRemoved && account.avatarUrl != null)
              ? resolveAvatarImage(account.avatarUrl!)
              : null;
          final hasPhotoToClear =
              _pendingAvatarPreviewBytes != null ||
              (!_avatarRemoved && account.avatarUrl != null);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.surfaceCard,
                          backgroundImage: previewImage,
                          child: previewImage == null
                              ? const Icon(
                                  Icons.account_circle,
                                  size: 96,
                                  color: AppColors.mutedText,
                                )
                              : null,
                        ),
                        // Edit/upload badge — always shown, lets the doctor
                        // pick a replacement photo (or the first one). Only
                        // staged locally until "حفظ التغييرات" is pressed.
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: brandBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Delete badge — only when there's a photo (existing
                        // or freshly picked) to clear.
                        if (hasPhotoToClear)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: _removeAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          label: 'الاسم الكامل',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'التخصص الطبي',
                          controller: _specialtyController,
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
