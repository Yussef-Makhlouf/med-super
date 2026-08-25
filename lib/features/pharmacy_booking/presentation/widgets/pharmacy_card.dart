import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';

/// A single pharmacy card in the step-2 selection list: logo + name/address,
/// a distance/rating meta row, a live-status row, then a trailing "اختر"
/// CTA — filled for the currently-selected pharmacy, outlined/muted for the
/// rest, and visually disabled for a pharmacy that is currently closed.
class PharmacyCard extends StatelessWidget {
  const PharmacyCard({
    required this.pharmacy,
    required this.isSelected,
    required this.onSelect,
    this.onViewDetails,
    super.key,
  });

  final Pharmacy pharmacy;
  final bool isSelected;
  final VoidCallback onSelect;

  /// Tapping the pharmacy's name/address (as opposed to the trailing "اختر"
  /// CTA) opens its full profile first — an optional drill-down, so the
  /// patient can either commit straight from this compact card (unchanged
  /// behavior) or read more before deciding. Null hides no UI; it just makes
  /// that area non-interactive, same as before this was added.
  final VoidCallback? onViewDetails;

  static const _openDot = Color(0xFF22C55E);

  /// Formats the review count the way the mockup shows it — abbreviated to
  /// one decimal + "k" once it reaches four digits (e.g. `1200` -> `1.2k`),
  /// otherwise the plain integer.
  String _formatRatingCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = !pharmacy.status.state.isOpen;

    return Container(
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
                  args: [pharmacy.distanceKm.toStringAsFixed(1)],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText2,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.star, size: 14, color: AppColors.ratingAmber),
              const SizedBox(width: 4),
              Text(
                '${pharmacy.rating}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pharmacy_booking.select_pharmacy.rating_count'.tr(
                  args: [_formatRatingCount(pharmacy.ratingCount)],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          // Status text takes the remaining space (and ellipsizes), pushing
          // the CTA — a compact pill, not full-width — to the row's end
          // (the left edge, in RTL), matching the mockup exactly.
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isClosed ? AppColors.errorRed : _openDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pharmacy.status.time == null
                            ? pharmacy.status.state.labelKey.tr()
                            : pharmacy.status.state.labelKey.tr(
                                args: [pharmacy.status.time!],
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isClosed ? AppColors.errorRed : _openDot,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CtaButton(
                isSelected: isSelected,
                isClosed: isClosed,
                onSelect: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.isSelected,
    required this.isClosed,
    required this.onSelect,
  });

  final bool isSelected;
  final bool isClosed;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final label = 'pharmacy_booking.select_pharmacy.choose_cta'.tr();

    // A compact pill, not a full-width button — the mockup pairs it with
    // the status text on the same row, so it must only take as much width
    // as its label needs.
    final button = isClosed
        // A closed pharmacy can't fulfil the order right now, so its CTA
        // reads visually disabled (per the mockup's muted 3rd card) — it's
        // still a real button rather than fully inert, in case the patient
        // wants to queue the request anyway.
        ? AppButton.outlined(
            label: label,
            onPressed: onSelect,
            foregroundColor: AppColors.mutedText2,
            borderRadius: AppRadii.pill,
          )
        : isSelected
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
