import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

/// A single lab card in the step-2 selection list, matching the Figma
/// "Lab Card" component: rating + name + logo on top, distance/address +
/// status chip below, the starting price, then an info button next to a
/// full-width "اختار المختبر" CTA — every card always shows its own CTA
/// (there's no separate "selected vs. not" card state in this design; the
/// selection border below is a light additive touch for the map/list
/// cross-highlight, not something the mockup itself shows).
class LabPartnerCard extends StatelessWidget {
  const LabPartnerCard({
    required this.partner,
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  final LabPartner partner;
  final bool isSelected;
  final VoidCallback onSelect;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                partner.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                partner.address,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'lab_booking.select_lab.starting_price_label'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText2,
                ),
              ),
              Text(
                '${partner.startingPrice} ج.م',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.patientPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isSelected ? AppColors.patientPrimary : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.patientPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo tile sits at the reading-start side (right, in RTL) —
              // rendered first here so Row's RTL layout places it there,
              // matching the mockup (rating badge is the trailing/left
              // element, not the logo).
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  border: Border.all(color: AppColors.borderSubtle),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.biotech_outlined,
                  size: 20,
                  color: AppColors.patientPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  partner.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${partner.rating}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star,
                      size: 13,
                      color: AppColors.ratingAmber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status chip on its own row (under the rating, at the same
          // trailing/left edge) — not sharing a row with the address.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _StatusChip(status: partner.status),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 13,
                color: AppColors.mutedText2,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${'lab_booking.select_lab.distance_km'.tr(args: ['${partner.distanceKm}'])} - ${partner.address}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'lab_booking.select_lab.starting_price_label'.tr(),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
          ),
          Text(
            '${partner.startingPrice} ج.م',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.patientPrimary,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _showDetails(context),
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppColors.mutedText2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.filled(
                  label: 'lab_booking.select_lab.choose_cta'.tr(),
                  onPressed: onSelect,
                  fullWidth: true,
                  // Explicit brand color/radius — see the matching comment
                  // in lab_request_upload_screen.dart: the shared
                  // ElevatedButton theme default is colorScheme.primary
                  // (brandBlue), a visibly different blue than
                  // AppColors.patientPrimary used everywhere else in this
                  // card and flow. Must match the mockup exactly.
                  backgroundColor: AppColors.patientPrimary,
                  // Without this, ElevatedButton's default M3 style
                  // computes the label color against the *theme's*
                  // primary rather than this explicit override, landing on
                  // a low-contrast near-invisible blue-on-blue label.
                  foregroundColor: Colors.white,
                  borderRadius: AppRadii.xl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live operating status chip rendered on each [LabPartnerCard] — green for
/// open, amber for busy, red/gray for closed. Colors are defined locally
/// (not in [AppColors]) since this token set is specific to this chip.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LabPartnerStatus status;

  static const _openBg = Color(0xFFDCFCE7);
  static const _openText = Color(0xFF15803D);
  static const _closedBg = Color(0xFFFEE2E2);
  static const _closedText = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      LabPartnerStatus.openNow => (_openBg, _openText),
      LabPartnerStatus.closedNow => (_closedBg, _closedText),
      LabPartnerStatus.busyNow => (
        AppColors.warningAmberBg,
        AppColors.warningAmberText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelKey.tr(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
