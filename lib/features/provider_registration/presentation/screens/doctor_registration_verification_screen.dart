import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/file_upload_card.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/uploaded_file_tile.dart';

class DoctorRegistrationVerificationScreen extends ConsumerWidget {
  const DoctorRegistrationVerificationScreen({super.key});

  /// Picks a file and enforces [maxMb]. On oversize, shows a clear SnackBar
  /// instead of silently dropping the file (resolved open decision #2).
  ///
  /// file_picker's web implementation resolves the pick only after reading
  /// the full file into memory (`withData: true` by default), racing a
  /// hard-coded 1-second "was this a cancel?" timeout — on anything slower
  /// than that it silently completes with null and the file is lost with
  /// no error at all. We never touch the file's bytes (mock app, we only
  /// need the name/size), so `withReadStream: true` skips that read and
  /// resolves immediately after the native `change` event, avoiding the
  /// race. The try/catch below still guards the separate null-check bug in
  /// its own change handler (a known upstream web issue).
  Future<void> _pickAndAdd(
    BuildContext context,
    WidgetRef ref,
    DocumentType type,
    int maxMb,
  ) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
        withReadStream: true,
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
    final files = result?.files ?? const <PlatformFile>[];
    final file = files.isEmpty ? null : files.first;
    if (file == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'provider_registration.verification.no_file_selected'.tr(),
          ),
        ),
      );
      return;
    }

    if (file.size > maxMb * 1024 * 1024) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'provider_registration.verification.file_too_large'.tr(
              args: ['$maxMb'],
            ),
          ),
        ),
      );
      return;
    }

    ref
        .read(registrationFormControllerProvider.notifier)
        .addDocument(
          UploadedDocument(
            id: '${type.name}-${DateTime.now().microsecondsSinceEpoch}',
            fileName: file.name,
            sizeBytes: file.size,
            // `PlatformFile.path` throws on web instead of returning null —
            // never accessed here since this is a mock-only app (no real
            // upload), so the filename alone is enough to identify it.
            localPath: kIsWeb ? '' : (file.path ?? ''),
            type: type,
          ),
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'provider_registration.verification.file_added'.tr(args: [file.name]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(registrationFormControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                children: [
                  StepProgressHeader(
                    stepLabels: [
                      'provider_registration.step_basic_info'.tr(),
                      'provider_registration.step_verification'.tr(),
                      'provider_registration.step_clinic_schedule'.tr(),
                      'provider_registration.step_review'.tr(),
                    ],
                    currentStep: 1,
                    accentColor: AppColors.providerPrimary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'provider_registration.verification.title'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'provider_registration.verification.subtitle'.tr(),
                    style: const TextStyle(color: AppColors.bodyText),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: AppColors.infoTealBg,
                      border: Border.all(color: const Color(0x1A006A63)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'provider_registration.verification.callout_title'
                                    .tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.infoTealText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'provider_registration.verification.callout_body'
                                    .tr(),
                                style: const TextStyle(
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.infoTealText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FileUploadCard(
                    icon: Icons.badge_outlined,
                    title: 'provider_registration.verification.license_title'
                        .tr(),
                    maxSizeLabel:
                        'provider_registration.verification.max_size_5mb'.tr(),
                    onTap: () => _pickAndAdd(
                      context,
                      ref,
                      DocumentType.medicalLicense,
                      5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FileUploadCard(
                    icon: Icons.badge_outlined,
                    title:
                        'provider_registration.verification.national_id_title'
                            .tr(),
                    maxSizeLabel:
                        'provider_registration.verification.max_size_5mb'.tr(),
                    onTap: () =>
                        _pickAndAdd(context, ref, DocumentType.nationalId, 5),
                  ),
                  const SizedBox(height: 16),
                  FileUploadCard(
                    icon: Icons.school_outlined,
                    title:
                        'provider_registration.verification.certificate_title'
                            .tr(),
                    maxSizeLabel:
                        'provider_registration.verification.max_size_10mb'.tr(),
                    onTap: () => _pickAndAdd(
                      context,
                      ref,
                      DocumentType.specialtyCertificate,
                      10,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'provider_registration.verification.uploaded_files'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final doc in draft.documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UploadedFileTile(
                        document: doc,
                        onRemove: () => ref
                            .read(registrationFormControllerProvider.notifier)
                            .removeDocument(doc.id),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.filled(
                          label: 'provider_registration.continue_cta'.tr(),
                          onPressed: draft.verificationComplete
                              ? () => context.push(
                                  '/provider/registration/clinic-schedule',
                                )
                              : null,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          backgroundColor: AppColors.providerPrimary,
                          foregroundColor: Colors.white,
                          borderRadius: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppButton.text(
                        label: 'provider_registration.back_cta'.tr(),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ],
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
          Expanded(
            child: Text(
              'provider_registration.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
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
