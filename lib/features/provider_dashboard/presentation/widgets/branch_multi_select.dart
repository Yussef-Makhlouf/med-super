import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';

/// Multi-select list of the doctor's own branches, used by Add/Edit Assistant
/// to choose which of the doctor's branches a given assistant is assigned to.
/// Unlike [DoctorClinic.displayTitle] (used by single-select branch filters
/// elsewhere), each tile shows [DoctorClinic.displayAddressLine] as the title
/// and the city as the subtitle — the same convention, just per-tile instead
/// of a single combined line, so two branches of the same clinic still read
/// distinctly in a checklist.
class BranchMultiSelect extends StatelessWidget {
  const BranchMultiSelect({
    super.key,
    required this.branches,
    required this.selectedBranchIds,
    required this.onChanged,
  });

  final List<DoctorClinic> branches;
  final Set<String> selectedBranchIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return Text(
        'assistants.no_branches_available'.tr(),
        style: const TextStyle(fontSize: 13, color: AppColors.mutedText2),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          for (final branch in branches)
            CheckboxListTile(
              value: selectedBranchIds.contains(branch.clinicBranchId),
              onChanged: (checked) {
                final next = Set<String>.from(selectedBranchIds);
                if (checked ?? false) {
                  next.add(branch.clinicBranchId);
                } else {
                  next.remove(branch.clinicBranchId);
                }
                onChanged(next);
              },
              activeColor: brandBlue,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                branch.displayAddressLine,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              subtitle: Text(
                branch.address.city,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
              ),
            ),
        ],
      ),
    );
  }
}
