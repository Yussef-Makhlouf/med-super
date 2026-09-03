import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_cost_estimate.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_cost_estimate_section.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_edit_modal.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/payment_method_option.dart';

/// Step 3 (final) of the lab booking flow — review the uploaded request,
/// pick a payment method, confirm/edit the service method, see an
/// *estimated* cost, and submit the request for lab review.
///
/// Unlike the old schedule/payment step this replaces, nothing here is a
/// final confirmed booking: the lab still has to review the uploaded
/// image(s) before the price and any prep instructions are known.
class LabReviewScreen extends ConsumerStatefulWidget {
  const LabReviewScreen({super.key});

  @override
  ConsumerState<LabReviewScreen> createState() => _LabReviewScreenState();
}

class _LabReviewScreenState extends ConsumerState<LabReviewScreen> {
  bool _agreedToTerms = false;
  bool _confirming = false;

  Future<void> _editServiceMethod(LabServiceType serviceType) async {
    if (serviceType == LabServiceType.homeCollection) {
      await showLabScheduleEditModal(context);
    } else {
      // Branch-visit has no day/time/address to edit here — "edit" means
      // changing the service-type choice itself (branch visit vs. home
      // collection), which is made on step 1, not re-picking a lab on
      // step 2. Popping back to step 2 would edit the wrong thing.
      context.push('/patient/lab/upload');
    }
  }

  Future<void> _confirm({
    required LabPartner? partner,
    required List<LabRequestImage> images,
    required LabServiceType? serviceType,
  }) async {
    if (partner == null || serviceType == null || images.isEmpty) return;

    setState(() => _confirming = true);
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final isHome = serviceType == LabServiceType.homeCollection;
    final result = await ref
        .read(confirmLabBookingUseCaseProvider)
        .call(
          labId: partner.id,
          images: images,
          serviceType: serviceType,
          paymentMethod: paymentMethod,
          scheduledDate: isHome ? ref.read(selectedScheduleDayProvider) : null,
          scheduledTime: isHome ? ref.read(selectedTimeSlotProvider) : null,
          address: isHome ? ref.read(selectedLabAddressProvider) : null,
        );
    if (!mounted) return;
    setState(() => _confirming = false);
    result.when(
      ok: (confirmation) =>
          context.push('/patient/lab/confirmation', extra: confirmation),
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lab_booking.select_lab.confirm_error'.tr())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final images = ref.watch(uploadedLabRequestImagesProvider);
    final serviceType = ref.watch(selectedLabServiceTypeProvider);

    final partners = ref.watch(labPartnersProvider).value ?? const [];
    final explicitLabId = ref.watch(selectedLabPartnerProvider);
    final selectedLabId =
        explicitLabId ?? (partners.isEmpty ? null : partners.first.id);
    final matchingPartners = partners.where((p) => p.id == selectedLabId);
    final partner = matchingPartners.isEmpty ? null : matchingPartners.first;

    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final selectedDay = ref.watch(selectedScheduleDayProvider);
    final selectedTime = ref.watch(selectedTimeSlotProvider);
    final selectedAddress = ref.watch(selectedLabAddressProvider);

    final isHome = serviceType == LabServiceType.homeCollection;
    // The tests estimate is the partner's `startingPrice` — the same
    // number shown as "starting from" in step 2 — since the actual tests
    // requested are only known once the lab manually reviews the uploaded
    // image; see LAB_BOOKING_FLOW_TODO_AR.md open decision #1.
    final testsEstimate = partner?.startingPrice ?? 0;
    final homeFee = isHome ? kLabHomeServiceFeeEgp : 0;
    final estimate = LabCostEstimate(
      testsEstimate: testsEstimate,
      homeFee: homeFee,
      total: testsEstimate + homeFee,
    );

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
                    labName: partner?.name,
                    distanceKm: partner?.distanceKm,
                    image: images.isEmpty ? null : images.first,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'lab_booking.review.payment_method_title'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<LabPaymentMethod>(
                    groupValue: selectedPayment,
                    onChanged: (method) {
                      if (method != null) {
                        ref
                            .read(selectedPaymentMethodProvider.notifier)
                            .select(method);
                      }
                    },
                    child: Column(
                      children: [
                        for (final method in LabPaymentMethod.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PaymentMethodOption(
                              method: method,
                              isSelected: method == selectedPayment,
                              onSelected: () => ref
                                  .read(selectedPaymentMethodProvider.notifier)
                                  .select(method),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ServiceMethodSection(
                    serviceType: serviceType,
                    day: selectedDay,
                    time: selectedTime,
                    address: selectedAddress,
                    locale: locale,
                    onEdit: () => _editServiceMethod(
                      serviceType ?? LabServiceType.branchVisit,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LabCostEstimateSection(estimate: estimate),
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
              isSubmitting: _confirming,
              // Disabled until the terms checkbox is ticked — payment
              // method and service method always carry a value by the
              // time this screen is reached, so the checkbox is the only
              // genuinely-optional gate left.
              onConfirm: _agreedToTerms
                  ? () => _confirm(
                      partner: partner,
                      images: images,
                      serviceType: serviceType,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatefulWidget {
  const _OrderSummaryCard({
    required this.labName,
    required this.distanceKm,
    required this.image,
  });

  final String? labName;
  final double? distanceKm;

  /// The first image the patient uploaded on step 1 — shown as the
  /// summary's thumbnail per the mockup.
  final LabRequestImage? image;

  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> {
  bool _expanded = false;

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
              _Thumbnail(image: widget.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.labName != null)
                      Text(
                        widget.labName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.patientPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    if (widget.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: AppColors.mutedText2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'lab_booking.select_lab.distance_km'.tr(
                              args: ['${widget.distanceKm}'],
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.mutedText2,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'lab_booking.review.request_description'.tr(),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.mutedText2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image});

  final LabRequestImage? image;

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
  const _ServiceMethodSection({
    required this.serviceType,
    required this.day,
    required this.time,
    required this.address,
    required this.locale,
    required this.onEdit,
  });

  final LabServiceType? serviceType;
  final DateTime day;
  final String? time;
  final String address;
  final String locale;
  final VoidCallback onEdit;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'lab_booking.review.service_method_title'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: Text(
                  'lab_booking.review.edit_cta'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.patientPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home-collection icon rendered green per the mockup (no
              // dedicated green token exists in AppColors yet, so the
              // closest existing semantic accent — teal — is reused for
              // both service types here).
              Icon(
                isHome ? Icons.home_outlined : Icons.apartment_outlined,
                size: 20,
                color: AppColors.tealAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedType.titleKey.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    if (isHome) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          AppFormatters.shortDate(day, locale: locale),
                          if (time != null)
                            AppFormatters.time12h(time!, locale: locale),
                        ].join(' - '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: AppColors.mutedText2,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
