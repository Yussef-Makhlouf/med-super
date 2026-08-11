import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
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

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false) || _specialtyId == null) {
      return;
    }
    ref
        .read(registrationFormControllerProvider.notifier)
        .updateBasicInfo(
          fullName: _nameController.text.trim(),
          specialty: _specialtyId,
          degree: _degreeController.text.trim(),
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
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _pickSpecialty(lookups.specialties),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText:
                                      'provider_registration.basic_info.specialty_label'
                                          .tr(),
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
                              onPressed: _continue,
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
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward),
          ),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProfilePhotoUpload extends ConsumerWidget {
  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
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
    if (file == null) return;
    ref
        .read(registrationFormControllerProvider.notifier)
        .updateProfilePhoto(file.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoName = ref.watch(
      registrationFormControllerProvider.select((d) => d.profilePhotoLocalPath),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              photoName == null
                  ? Icons.camera_alt_outlined
                  : Icons.check_circle,
              color: photoName == null ? null : AppColors.tealAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'provider_registration.basic_info.photo_title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                Text(
                  photoName ??
                      'provider_registration.basic_info.photo_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.bodyText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickPhoto(context, ref),
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text(
                    'provider_registration.basic_info.photo_upload_cta'.tr(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
