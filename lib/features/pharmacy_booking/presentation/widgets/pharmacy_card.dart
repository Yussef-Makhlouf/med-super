import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';

/// A single pharmacy branch card in the step-2 selection list: logo +
/// name/address, a distance row (hidden when the device's location isn't
/// known), then a trailing "اختر" CTA — filled for the currently-selected
/// branch, outlined for the rest.
///
/// Rating and live open/closed status were dropped 2026-08-29 along with
/// the same fields on [Pharmacy] — no rating or operating-hours data exists
/// on the real `pharmacy_branches`/`pharmacies` tables to back them.
class PharmacyCard extends StatelessWidget {
  const PharmacyCard({
    required this.pharmacy,
    required this.isSelected,
    required this.onSelect,
    this.onViewDetails,
    this.disabled = false,
    super.key,
  });

  final Pharmacy pharmacy;
  final bool isSelected;
  final VoidCallback onSelect;

  /// True when the chosen delivery method needs a delivery-capable branch
  /// and this one isn't — shown (not hidden) so the patient can see it
  /// exists, but greyed out and not selectable, matching how the "choose"
  /// CTA already goes null-disabled rather than removing the button.
  final bool disabled;

  /// Tapping the pharmacy's name/address (as opposed to the trailing "اختر"
  /// CTA) opens its full profile first — an optional drill-down, so the
  /// patient can either commit straight from this compact card (unchanged
  /// behavior) or read more before deciding. Null hides no UI; it just makes
  /// that area non-interactive, same as before this was added.
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isSelected ? AppColors.patientPrimary : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Color(0xFF15803D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pharmacy.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onViewDetails != null)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedText2,
                  ),
              ],
            ),
          ),
          if (pharmacy.distanceKm != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 14,
                  color: AppColors.mutedText2,
                ),
                const SizedBox(width: 4),
                Text(
                  'pharmacy_booking.select_pharmacy.distance_km'.tr(
                    args: [pharmacy.distanceKm!.toStringAsFixed(1)],
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              pharmacy.deliveryCapable
                  ? const _DeliveryBadge()
                  : (disabled
                        ? const _NoDeliveryBadge()
                        : const SizedBox.shrink()),
              _CtaButton(
                isSelected: isSelected,
                onSelect: disabled ? null : onSelect,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// `pharmacy_branches.delivery_capable` — real backend data. Fills the
/// space next to the "اختر" CTA that used to hold the (now-removed)
/// open/closed status text; hidden entirely for a non-delivering branch
/// rather than showing a "no delivery" negative badge.
class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.delivery_dining_outlined,
            size: 16,
            color: AppColors.tealAccent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'pharmacy_booking.select_pharmacy.delivery_available'.tr(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.tealAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of [_DeliveryBadge] only when the card is [PharmacyCard.disabled]
/// for lacking delivery — otherwise a non-delivering branch simply shows no
/// badge at all (pickup flows don't care), so this stays out of the common
/// case rather than becoming a second always-visible negative badge.
class _NoDeliveryBadge extends StatelessWidget {
  const _NoDeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.do_not_disturb_alt_outlined,
            size: 14,
            color: AppColors.mutedText2,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'pharmacy_booking.select_pharmacy.delivery_unavailable'.tr(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.isSelected, required this.onSelect});

  final bool isSelected;

  /// Null (not just a no-op) when the card is disabled, so `AppButton`
  /// itself renders in its disabled visual state rather than looking
  /// pressable while doing nothing.
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final label = 'pharmacy_booking.select_pharmacy.choose_cta'.tr();

    // A compact pill, not a full-width button — matches the mockup's card
    // layout, which pairs it with a leading status/distance row.
    final button = isSelected
        ? AppButton.filled(
            label: label,
            onPressed: onSelect,
            backgroundColor: AppColors.patientPrimary,
            foregroundColor: Colors.white,
            borderRadius: AppRadii.pill,
          )
        : AppButton.outlined(
            label: label,
            onPressed: onSelect,
            foregroundColor: AppColors.patientPrimary,
            borderRadius: AppRadii.pill,
          );

    return SizedBox(height: 40, child: button);
  }
}
