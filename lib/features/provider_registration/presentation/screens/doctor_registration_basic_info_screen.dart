import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/utils/validators.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/provider_registration/domain/entities/lookup_item.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_lookups_providers.dart';

class DoctorRegistrationBasicInfoScreen extends ConsumerStatefulWidget {
  const DoctorRegistrationBasicInfoScreen({super.key});

  @override
  ConsumerState<DoctorRegistrationBasicInfoScreen> createState() =>
      _DoctorRegistrationBasicInfoScreenState();
}

class _DoctorRegistrationBasicInfoScreenState
    extends ConsumerState<DoctorRegistrationBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();
  late final _degreeController = TextEditingController();
  late final _emailController = TextEditingController();
  late final _experienceController = TextEditingController();
  late final _bioController = TextEditingController();

  /// Stores the specialty's [LookupItem.id] — never a hardcoded label.
  String? _specialtyId;
  String? _specialtyLabel;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registrationFormControllerProvider);
    _nameController.text = draft.fullName;
    _degreeController.text = draft.degree;
    _emailController.text = draft.email;
    _experienceController.text = draft.experienceYears == 0
        ? ''
        : '${draft.experienceYears}';
    _bioController.text = draft.bio;
    _specialtyId = draft.specialty;
  }

  Future<void> _pickSpecialty(List<LookupItem> specialties) async {
    final selected = await showModalBottomSheet<LookupItem>(
      context: context,
      builder: (context) => ListView(
        children: specialties
            .map(
              (s) =>
                  ListTile(title: Text(s.label), onTap: () => context.pop(s)),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _specialtyId = selected.id;
        _specialtyLabel = selected.label;
      });
    }
  }

  /// Mirrors [DoctorRegistrationDraft.basicInfoComplete] against the local
  /// field state, since nothing is written to the draft controller until
  /// [_continue] runs — gating on the draft itself would never re-enable.
  bool get _isBasicInfoValid =>
      _nameController.text.trim().isNotEmpty &&
      _specialtyId != null &&
      _degreeController.text.trim().isNotEmpty &&
      Validators.email(_emailController.text) == null &&
      (int.tryParse(_experienceController.text) ?? 0) > 0;

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false) || !_isBasicInfoValid) {
      return;
    }
    ref
        .read(registrationFormControllerProvider.notifier)
        .updateBasicInfo(
          fullName: _nameController.text.trim(),
          specialty: _specialtyId,
          degree: _degreeController.text.trim(),
          email: _emailController.text.trim(),
          experienceYears: int.tryParse(_experienceController.text) ?? 0,
          bio: _bioController.text.trim(),
        );
    context.push('/provider/registration/verification');
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(registrationLookupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: AsyncValueView(
                value: lookupsAsync,
                onRetry: () => ref.invalidate(registrationLookupsProvider),
                data: (lookups) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                  children: [
                    StepProgressHeader(
                      stepLabels: [
                        'provider_registration.step_basic_info'.tr(),
                        'provider_registration.step_verification'.tr(),
                        'provider_registration.step_clinic_schedule'.tr(),
                        'provider_registration.step_review'.tr(),
                      ],
                      currentStep: 0,
                      accentColor: AppColors.providerPrimary,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'provider_registration.basic_info.welcome'.tr(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'provider_registration.basic_info.subtitle'.tr(),
                              style: const TextStyle(color: AppColors.bodyText),
                            ),
                            const SizedBox(height: 24),
                            _ProfilePhotoUpload(),
                            const SizedBox(height: 24),
                            AppTextField(
                              label:
                                  'provider_registration.basic_info.full_name_label'
                                      .tr(),
                              controller: _nameController,
                              hint:
                                  'provider_registration.basic_info.full_name_hint'
                                      .tr(),
                              prefix: const Icon(Icons.person_outline),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _pickSpecialty(lookups.specialties),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText:
                                      'provider_registration.basic_info.specialty_label'
                                          .tr(),
                                  prefixIcon: const Icon(
                                    Icons.keyboard_arrow_down,
                                  ),
                                ),
                                child: Text(
                                  _specialtyLabel ??
                                      'provider_registration.basic_info.specialty_hint'
                                          .tr(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label:
                                  'provider_registration.basic_info.degree_label'
                                      .tr(),
                              controller: _degreeController,
                              hint:
                                  'provider_registration.basic_info.degree_hint'
                                      .tr(),
                              prefix: const Icon(Icons.school_outlined),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label:
                                  'provider_registration.basic_info.email_label'
                                      .tr(),
                              hint:
                                  'provider_registration.basic_info.email_hint'
                                      .tr(),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefix: const Icon(Icons.email_outlined),
                              onChanged: (_) => setState(() {}),
                            ),
                            if (Validators.email(_emailController.text) != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  Validators.email(_emailController.text)!,
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label:
                                  'provider_registration.basic_info.experience_label'
                                      .tr(),
                              controller: _experienceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              prefix: const Icon(Icons.access_time),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 3,
                              maxLength: 250,
                              decoration: InputDecoration(
                                labelText:
                                    'provider_registration.basic_info.bio_label'
                                        .tr(),
                                hintText:
                                    'provider_registration.basic_info.bio_hint'
                                        .tr(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton.filled(
                              label: 'provider_registration.continue_cta'.tr(),
                              onPressed: _isBasicInfoValid ? _continue : null,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              backgroundColor: AppColors.providerPrimary,
                              foregroundColor: Colors.white,
                              borderRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderMedium)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'تسجيل الطبيب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.providerPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_forward,
              color: AppColors.providerPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoUpload extends ConsumerWidget {
  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'provider_registration.verification.pick_failed_retry'.tr(),
          ),
        ),
      );
      return;
    }
    final file = result?.files.isEmpty ?? true ? null : result!.files.first;
    if (file == null || file.bytes == null) return;
    ref
        .read(registrationFormControllerProvider.notifier)
        .updateProfilePhoto(
          file.name,
          // No real file storage in mock mode — carry the actual picked
          // bytes as a base64 data URI so it becomes the real avatar_url
          // after submission instead of being dropped.
          dataUri: 'data:image/jpeg;base64,${base64Encode(file.bytes!)}',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoName = ref.watch(
      registrationFormControllerProvider.select((d) => d.profilePhotoLocalPath),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final avatarSize = isCompact ? 64.0 : 96.0;
        final gap = isCompact ? 12.0 : 24.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  photoName == null
                      ? Icons.camera_alt_outlined
                      : Icons.check_circle,
                  color: photoName == null ? null : AppColors.tealAccent,
                  size: avatarSize * 0.33,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'provider_registration.basic_info.photo_title'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    Text(
                      photoName ??
                          'provider_registration.basic_info.photo_subtitle'
                              .tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickPhoto(context, ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'provider_registration.basic_info.photo_upload_cta'
                                  .tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
