import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/simple_success_screen.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_registration/domain/entities/region_codes.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_lookups_providers.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/review_section_card.dart';

class DoctorRegistrationReviewScreen extends ConsumerWidget {
  const DoctorRegistrationReviewScreen({super.key});

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref, {
    required String? specialtyLabel,
    required String? cityLabel,
    required String phone,
  }) async {
    final result = await ref
        .read(registrationFormControllerProvider.notifier)
        .submit(
          specialtyLabel: specialtyLabel,
          cityLabel: cityLabel,
          phone: phone,
        );
    if (!context.mounted) return;
    if (result.isOk) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (routeContext) => SimpleSuccessScreen(
            title: 'provider_registration.review.success_title'.tr(),
            message: 'provider_registration.review.success_message'.tr(),
            primaryActionLabel: 'provider_registration.review.back_home_cta'
                .tr(),
            accentColor: AppColors.providerPrimary,
            onPrimaryAction: () => routeContext.go('/provider/home'),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('provider_registration.review.submit_error'.tr()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(registrationFormControllerProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final lookupsAsync = ref.watch(registrationLookupsProvider);
    final phone = session?.user.phone ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: AsyncValueView(
          value: lookupsAsync,
          onRetry: () => ref.invalidate(registrationLookupsProvider),
          data: (lookups) {
            final specialtyLabel = lookups.specialties
                .firstWhereOrNull((s) => s.id == draft.specialty)
                ?.label;
            final cityLabel = lookups.cities
                .firstWhereOrNull((c) => c.id == draft.city)
                ?.label;
            final regionLabel = kRegionCodes
                .firstWhereOrNull((r) => r.id == draft.regionCode)
                ?.label;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '100%',
                      style: TextStyle(
                        color: AppColors.providerPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'provider_registration.review.step_caption'.tr(),
                      style: const TextStyle(
                        color: AppColors.providerPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: const LinearProgressIndicator(
                    value: 1,
                    minHeight: 8,
                    color: AppColors.providerPrimary,
                    backgroundColor: Color(0x1AFFFFFF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'provider_registration.review.title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'provider_registration.review.subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ReviewSectionCard(
                  title: 'provider_registration.review.personal_info_title'
                      .tr(),
                  icon: Icons.person_outline,
                  onEdit: () => context.goNamed('providerRegBasicInfo'),
                  rows: [
                    ReviewRow(
                      'provider_registration.review.full_name_row'.tr(),
                      draft.fullName,
                    ),
                    ReviewRow(
                      'provider_registration.review.phone_row'.tr(),
                      phone,
                    ),
                    if (draft.email.trim().isNotEmpty)
                      ReviewRow(
                        'provider_registration.review.email_row'.tr(),
                        draft.email,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                ReviewSectionCard(
                  title: 'provider_registration.review.professional_info_title'
                      .tr(),
                  icon: Icons.badge_outlined,
                  onEdit: () => context.goNamed('providerRegVerification'),
                  rows: [
                    ReviewRow(
                      'provider_registration.review.specialty_row'.tr(),
                      specialtyLabel ?? '—',
                    ),
                    ReviewRow(
                      'provider_registration.review.experience_row'.tr(),
                      'provider_registration.review.experience_years_value'.tr(
                        args: ['${draft.experienceYears}'],
                      ),
                    ),
                    ReviewRow(
                      'provider_registration.review.license_number_row'.tr(),
                      draft.licenseNumber.trim().isEmpty
                          ? '—'
                          : draft.licenseNumber,
                    ),
                  ],
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'provider_registration.review.documents_row'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final doc in draft.documents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• ${doc.fileName}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ReviewSectionCard(
                  title: 'provider_registration.review.clinic_info_title'.tr(),
                  icon: Icons.local_hospital_outlined,
                  onEdit: () => context.goNamed('providerRegClinicSchedule'),
                  rows: [
                    ReviewRow(
                      'provider_registration.review.clinic_name_row'.tr(),
                      draft.clinicName,
                    ),
                    ReviewRow(
                      'provider_registration.review.city_row'.tr(),
                      cityLabel ?? '—',
                    ),
                    ReviewRow(
                      'provider_registration.review.region_row'.tr(),
                      regionLabel ?? '—',
                    ),
                    ReviewRow(
                      'provider_registration.review.clinic_address_row'.tr(),
                      draft.clinicAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.providerPrimary.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.providerPrimary.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: draft.agreedToTerms,
                        onChanged: (v) => ref
                            .read(registrationFormControllerProvider.notifier)
                            .setAgreedToTerms(v ?? false),
                        activeColor: AppColors.providerPrimary,
                      ),
                      Expanded(
                        child: Text(
                          'provider_registration.review.terms_agreement'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.surfaceMuted),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'provider_registration.review.confirmation_title'
                                  .tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'provider_registration.review.confirmation_body'
                                  .tr(),
                              style: const TextStyle(color: AppColors.bodyText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.info_outline, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton.filled(
                  label: 'provider_registration.review.submit_cta'.tr(),
                  onPressed: draft.agreedToTerms
                      ? () => _submit(
                          context,
                          ref,
                          specialtyLabel: specialtyLabel,
                          cityLabel: cityLabel,
                          phone: phone,
                        )
                      : null,
                  icon: const Icon(Icons.send, size: 16),
                  backgroundColor: AppColors.providerPrimary,
                  foregroundColor: Colors.white,
                  borderRadius: 9999,
                  fullWidth: true,
                ),
                const SizedBox(height: 12),
                AppButton.outlined(
                  label: 'provider_registration.review.save_draft_cta'.tr(),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'provider_registration.review.draft_saved'.tr(),
                        ),
                      ),
                    );
                    context.go('/provider/home');
                  },
                  foregroundColor: AppColors.providerPrimary,
                  borderRadius: 9999,
                  fullWidth: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
