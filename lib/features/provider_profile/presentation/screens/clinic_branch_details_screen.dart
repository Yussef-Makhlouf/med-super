import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/clinic_branch_providers.dart';

const _ink = Color(0xFF1A2B4A);
const _muted = Color(0xFF8A94A6);

/// Clinic branch detail — mirrors `doctor_details_screen.dart`'s
/// card/section design language for the same feature family.
class ClinicBranchDetailsScreen extends ConsumerWidget {
  const ClinicBranchDetailsScreen({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBranch = ref.watch(clinicBranchProvider(branchId));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: brandBlue),
        ),
        title: Text(
          'clinic_branch.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: AsyncValueView(
        value: asyncBranch,
        onRetry: () => ref.invalidate(clinicBranchProvider(branchId)),
        data: (branch) => _BranchBody(branch: branch),
      ),
    );
  }
}

class _BranchBody extends StatelessWidget {
  const _BranchBody({required this.branch});

  final ClinicBranch branch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(branch: branch),
        const SizedBox(height: 12),
        _AddressCard(address: branch.address),
        const SizedBox(height: 12),
        _ContactCard(branch: branch),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.branch});

  final ClinicBranch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            // pushReplacement (not push) — see the matching comment on
            // ClinicDetailsScreen's branch-card onTap: avoids an
            // ever-growing clinic→branch→clinic→branch stack.
            onTap: () => context.pushReplacement(
              '/patient/clinics/${branch.clinicId}',
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFDCE8FF),
                  child: Icon(
                    Icons.local_hospital_outlined,
                    color: brandBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              branch.clinic.brandName,
                              style: textTheme.titleLarge?.copyWith(
                                color: brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (branch.status == ClinicBranchStatus.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: brandBlue,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        branch.clinic.legalName,
                        style: textTheme.bodyMedium?.copyWith(color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _muted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StatusChip(status: branch.status),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final ClinicBranchAddress address;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: brandBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'clinic_branch.address'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.line1,
            style: textTheme.bodyMedium?.copyWith(
              color: _ink.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.city}, ${address.regionCode}',
            style: textTheme.bodyMedium?.copyWith(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.branch});

  final ClinicBranch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_outlined, color: brandBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'clinic_branch.contact'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: AppFormatters.ltrIsolate(branch.phone),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: branch.ianaTimezone,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ClinicBranchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ClinicBranchStatus.verified => (
        'clinic_branch.status_verified'.tr(),
        const Color(0xFF22C55E),
      ),
      ClinicBranchStatus.pending => (
        'clinic_branch.status_pending'.tr(),
        const Color(0xFFF59E0B),
      ),
      ClinicBranchStatus.suspended => (
        'clinic_branch.status_suspended'.tr(),
        const Color(0xFFEF4444),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: brandBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _ink.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
