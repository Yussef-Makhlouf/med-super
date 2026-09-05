import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_controller.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';

/// Step 3 (final) of the lab booking flow — review the uploaded request and
/// chosen branch/service method, then submit the request for lab staff to
/// review.
///
/// Rebuilt 2026-09-05 to match the real backend exactly: no payment method,
/// no cost estimate, no home-collection day/time/address picker — none of
/// that is accepted by `POST /v1/lab-orders` (price/appointment/prep
/// instructions are only ever set later by lab staff via `SubmitLabQuoteUseCase`,
/// and payment is explicitly out of scope, `DEC-002`). Shipping those
/// controls anyway would mean fake pricing and inert selections; this
/// screen shows only what the real order actually carries.
class LabReviewScreen extends ConsumerStatefulWidget {
  const LabReviewScreen({super.key});

  @override
  ConsumerState<LabReviewScreen> createState() => _LabReviewScreenState();
}

class _LabReviewScreenState extends ConsumerState<LabReviewScreen> {
  bool _agreedToTerms = false;

  Future<void> _confirm({
    required LabBranch? branch,
    required LabServiceType? serviceType,
  }) async {
    if (branch == null || serviceType == null) return;
    final prescriptionId = ref
        .read(prescriptionUploadControllerProvider)
        .value
        ?.prescriptionId;
    if (prescriptionId == null) return;

    await ref
        .read(labOrderControllerProvider.notifier)
        .submit(
          labBranchId: branch.id,
          collectionType: serviceType.apiValue,
          prescriptionId: prescriptionId,
        );
    if (!mounted) return;

    final result = ref.read(labOrderControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lab_booking.select_lab.confirm_error'.tr())),
      );
      return;
    }
    final confirmation = LabBookingConfirmation(
      orderId: result.value!.labOrderId,
      branchName: branch.name,
      branchAddress: branch.address,
    );
    context.push('/patient/lab/confirmation', extra: confirmation);
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(uploadedLabRequestImagesProvider);
    final serviceType = ref.watch(selectedLabServiceTypeProvider);
    final isConfirming = ref.watch(labOrderControllerProvider).isLoading;

    final branches = ref.watch(labBranchesProvider).value ?? const [];
    final explicitBranchId = ref.watch(selectedLabBranchProvider);
    final selectedBranchId =
        explicitBranchId ?? (branches.isEmpty ? null : branches.first.id);
    final matchingBranches = branches.where((b) => b.id == selectedBranchId);
    final branch = matchingBranches.isEmpty ? null : matchingBranches.first;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              // Same step labels/order as the other two screens of this
              // flow — the stepper must read identically across all three.
              stepLabels: [
                'lab_booking.step_upload'.tr(),
                'lab_booking.step_select_lab'.tr(),
                'lab_booking.step_review'.tr(),
              ],
              currentStep: 2,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _OrderSummaryCard(
                    branchName: branch?.name,
                    branchAddress: branch?.address,
                    image: images.isEmpty ? null : images.first,
                  ),
                  const SizedBox(height: 24),
                  _ServiceMethodSection(serviceType: serviceType),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.mutedText2,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'lab_booking.review.estimate_disclaimer'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TermsCheckbox(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                  ),
                ],
              ),
            ),
            _SubmitBar(
              isSubmitting: isConfirming,
              // Disabled until the terms checkbox is ticked — service method
              // always carries a value by the time this screen is reached,
              // so the checkbox is the only genuinely-optional gate left.
              onConfirm: _agreedToTerms
                  ? () => _confirm(branch: branch, serviceType: serviceType)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.branchName,
    required this.branchAddress,
    required this.image,
  });

  final String? branchName;
  final String? branchAddress;
  final PrescriptionImage? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lab_booking.review.summary_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(image: image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lab_booking.review.request_description'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.tealAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'lab_booking.review.upload_success'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (branchName != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const Icon(
                    Icons.biotech_outlined,
                    size: 16,
                    color: AppColors.tealAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branchName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.patientPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (branchAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          branchAddress!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image});

  final PrescriptionImage? image;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image == null) return _fallback();

    // `Image.memory` (not `Image.file`/`dart:io`) — this must render on
    // every platform including Flutter Web, where there is no real
    // filesystem path to read `image.path` from at all.
    ImageProvider? provider;
    if (image.bytes != null) {
      provider = MemoryImage(image.bytes!);
    } else if (image.path.startsWith('http')) {
      provider = NetworkImage(image.path);
    }
    if (provider == null) return _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Image(
        image: provider,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.mutedText2),
    );
  }
}

class _ServiceMethodSection extends StatelessWidget {
  const _ServiceMethodSection({required this.serviceType});

  final LabServiceType? serviceType;

  @override
  Widget build(BuildContext context) {
    final resolvedType = serviceType ?? LabServiceType.branchVisit;
    final isHome = resolvedType == LabServiceType.homeCollection;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lab_booking.review.service_method_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isHome ? Icons.home_outlined : Icons.apartment_outlined,
                size: 20,
                color: AppColors.tealAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  resolvedType.titleKey.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.patientPrimary,
          ),
          Expanded(
            child: Text(
              'lab_booking.review.terms_agreement'.tr(),
              style: const TextStyle(fontSize: 13, color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isSubmitting, required this.onConfirm});

  final bool isSubmitting;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitting ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.patientPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'lab_booking.review.submit_cta'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Balances the trailing back button's width so the title stays
          // visually centered now that nothing occupies the leading slot.
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'lab_booking.review.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.patientPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
