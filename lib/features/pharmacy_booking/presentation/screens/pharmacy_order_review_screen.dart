import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';

/// Step 3 (final) of the pharmacy booking flow — review the uploaded
/// prescription, the chosen pharmacy and delivery method, see an
/// *estimated* payment summary, and submit the order.
///
/// Like the lab booking flow's review step, nothing here is a final
/// confirmed order: the pharmacist still has to review the uploaded
/// prescription image before the medication cost is known.
class PharmacyOrderReviewScreen extends ConsumerStatefulWidget {
  const PharmacyOrderReviewScreen({super.key});

  @override
  ConsumerState<PharmacyOrderReviewScreen> createState() =>
      _PharmacyOrderReviewScreenState();
}

class _PharmacyOrderReviewScreenState
    extends ConsumerState<PharmacyOrderReviewScreen> {
  bool _confirming = false;

  Future<void> _confirm({
    required Pharmacy? pharmacy,
    required List<PrescriptionImage> images,
  }) async {
    if (pharmacy == null || images.isEmpty) return;

    setState(() => _confirming = true);
    try {
      // No real backend for this mock flow yet — simulate the network
      // round trip the same way `pharmaciesProvider` does, then build a
      // mock confirmation locally.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final confirmation = PharmacyOrderConfirmation(
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}',
        pharmacyName: pharmacy.name,
      );
      if (!mounted) return;
      setState(() => _confirming = false);
      context.push('/patient/pharmacy/confirmation', extra: confirmation);
    } catch (_) {
      // Defensive branch only — nothing above can actually throw today,
      // there is no real backend call yet to fail.
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pharmacy_booking.review.confirm_error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(uploadedPrescriptionImagesProvider);
    final deliveryMethod = ref.watch(selectedDeliveryMethodProvider);

    final pharmacies = ref.watch(pharmaciesProvider).value ?? const [];
    final explicitPharmacyId = ref.watch(selectedPharmacyProvider);
    final selectedPharmacyId =
        explicitPharmacyId ?? (pharmacies.isEmpty ? null : pharmacies.first.id);
    final matchingPharmacies = pharmacies.where(
      (p) => p.id == selectedPharmacyId,
    );
    final pharmacy = matchingPharmacies.isEmpty
        ? null
        : matchingPharmacies.first;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              // Different label set from step 1's stepper, per the
              // transcribed screenshots — intentional, not a mismatch.
              stepLabels: [
                'pharmacy_booking.step_prescription'.tr(),
                'pharmacy_booking.step_details'.tr(),
                'pharmacy_booking.step_review'.tr(),
              ],
              currentStep: 2,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _OrderSummaryCard(
                    image: images.isEmpty ? null : images.first,
                    pharmacyName: pharmacy?.name,
                    pharmacyAddress: pharmacy?.address,
                  ),
                  const SizedBox(height: 16),
                  _DeliveryMethodSection(
                    method: deliveryMethod,
                    onEdit: () => context.push('/patient/pharmacy/upload'),
                  ),
                  const SizedBox(height: 16),
                  const _PaymentSummarySection(),
                ],
              ),
            ),
            _SubmitBar(
              isSubmitting: _confirming,
              onConfirm: () => _confirm(pharmacy: pharmacy, images: images),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.image,
    required this.pharmacyName,
    required this.pharmacyAddress,
  });

  final PrescriptionImage? image;
  final String? pharmacyName;
  final String? pharmacyAddress;

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
            'pharmacy_booking.review.summary_title'.tr(),
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
                      'pharmacy_booking.review.prescription_photo_label'.tr(),
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
                          'pharmacy_booking.review.upload_success'.tr(),
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
          if (pharmacyName != null) ...[
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
                    Icons.storefront_outlined,
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
                        pharmacyName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.patientPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (pharmacyAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          pharmacyAddress!,
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

    // `Image.memory` (not `Image.file`/`dart:io`) — must render on every
    // platform including Flutter Web, where `image.path` is just a display
    // name, not a real filesystem path.
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

class _DeliveryMethodSection extends StatelessWidget {
  const _DeliveryMethodSection({required this.method, required this.onEdit});

  final DeliveryMethod method;
  final VoidCallback onEdit;

  // Placeholder mock address for this mock flow — there is no real
  // saved-address feature yet, so a representative address is hardcoded
  // here rather than sourced from a provider or translation key.
  static const _mockHomeAddress =
      'حي العليا، الرياض، المملكة العربية السعودية. بالقرب من برج المملكة، مبنى رقم 4.';

  @override
  Widget build(BuildContext context) {
    final isHome = method == DeliveryMethod.homeDelivery;
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
                  'pharmacy_booking.review.delivery_method_title'.tr(),
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
                  'pharmacy_booking.review.edit_cta'.tr(),
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
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isHome
                    ? Icons.delivery_dining_outlined
                    : Icons.storefront_outlined,
                size: 20,
                color: AppColors.tealAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  method.titleKey.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          if (isHome) ...[
            const SizedBox(height: 12),
            // Full-width address box — a separate card-within-a-card below
            // the title row, not indented under it, matching the mockup.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceApp,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: AppColors.mutedText2,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'pharmacy_booking.review.home_label'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          _mockHomeAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSummarySection extends StatelessWidget {
  const _PaymentSummarySection();

  // Mock delivery fee — a hardcoded number, not a translation key, since
  // this is placeholder pricing rather than real localized copy.
  static const _mockDeliveryFee = '15 ج.م';

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
            'pharmacy_booking.review.payment_summary_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'pharmacy_booking.review.subtotal_label'.tr(),
            value: 'pharmacy_booking.review.subtotal_value'.tr(),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'pharmacy_booking.review.delivery_fee_label'.tr(),
            value: _mockDeliveryFee,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'pharmacy_booking.review.vat_label'.tr(),
            value: 'pharmacy_booking.review.vat_value'.tr(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
          _SummaryRow(
            label: 'pharmacy_booking.review.total_label'.tr(),
            value: 'pharmacy_booking.review.total_value'.tr(
              args: [_mockDeliveryFee],
            ),
            emphasized: true,
          ),
          const SizedBox(height: 16),
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
                    'pharmacy_booking.review.estimate_disclaimer'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText2,
                    ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: emphasized ? AppColors.patientPrimary : AppColors.mutedText2,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 15 : 14,
            color: emphasized ? AppColors.patientPrimary : AppColors.ink900,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
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
                    'pharmacy_booking.review.confirm_cta'.tr(),
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
          // visually centered, matching every other screen's header in this
          // flow. Deliberate deviation from the raw mockup: no "?" help icon
          // on this header (only the back arrow is kept).
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'pharmacy_booking.review.title'.tr(),
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
