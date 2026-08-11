import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';

/// A single lab card in the step-2 selection list, matching the Figma
/// "Lab Card" component (selected state gets a blue border + check badge).
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.patientPrimary
                  : AppColors.borderLight,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'lab_booking.select_lab.distance_km'.tr(
                            args: ['${partner.distanceKm}'],
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.mutedText2,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.borderMedium,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'lab_booking.select_lab.rating_count'.tr(
                            args: ['${partner.ratingCount}'],
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${partner.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink700,
                          ),
                        ),
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: AppColors.ratingAmber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.only(top: 13),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: isSelected
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isSelected)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onSelect,
                                customBorder: const StadiumBorder(
                                  side: BorderSide(
                                    color: AppColors.patientPrimary,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 9,
                                  ),
                                  child: Text(
                                    'lab_booking.select_lab.choose_cta'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.patientPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'lab_booking.select_lab.total_cost_label'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText2,
                                ),
                              ),
                              Text(
                                '${partner.totalPrice} ج.م',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.patientPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  border: Border.all(color: AppColors.borderSubtle),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.biotech_outlined,
                  color: AppColors.patientPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.patientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
