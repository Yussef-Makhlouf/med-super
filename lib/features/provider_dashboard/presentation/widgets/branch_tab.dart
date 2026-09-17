import 'package:flutter/material.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';

/// A tab labelled the same way a branch is identified in the doctor's own
/// "my clinics" list (`_ClinicBranchListTile`): the branch's city as the
/// bold title, with the street address alone as a muted subtitle
/// underneath. Shared across every branch-tabbed screen (Home, Schedule).
class BranchTab extends StatelessWidget {
  const BranchTab({required this.branch, super.key});

  final DoctorClinic branch;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              branch.address.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              branch.address.line1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
