import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/clinic_branch_providers.dart';
import 'package:solar_icons/solar_icons.dart';

/// Clinic branch detail — mirrors `doctor_details_screen.dart`'s
/// card/section design language for the same feature family.
///
/// A branch is the unit a patient browses and picks — there is no "clinic"
/// parent page to drill through first (a clinic name alone has no
/// address/phone to act on), so this screen never links back up to one.
class ClinicBranchDetailsScreen extends ConsumerWidget {
  const ClinicBranchDetailsScreen({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBranch = ref.watch(clinicBranchProvider(branchId));

    return Scaffold(
      backgroundColor: AppPalette.paper,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            SolarIconsOutline.arrowLeft,
            color: AppPalette.primary,
          ),
        ),
        title: Text(
          'clinic_branch.title'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPalette.ink),
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
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppPalette.primarySoft,
                child: Icon(
                  SolarIconsOutline.hospital,
                  color: AppPalette.primary,
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
                              color: AppPalette.primary,
                            ),
                          ),
                        ),
                        if (branch.status == ClinicBranchStatus.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            SolarIconsBold.shieldCheck,
                            color: AppPalette.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.clinic.legalName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                SolarIconsOutline.mapPointHospital,
                color: AppPalette.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'clinic_branch.address'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.line1,
            style: textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.city}, ${address.regionCode}',
            style: textTheme.bodyMedium?.copyWith(color: AppPalette.inkMuted),
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
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                SolarIconsOutline.phoneCalling,
                color: AppPalette.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'clinic_branch.contact'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: SolarIconsOutline.phone,
            label: AppFormatters.ltrIsolate(branch.phone),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: SolarIconsOutline.clockCircle,
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
        AppPalette.success,
      ),
      ClinicBranchStatus.pending => (
        'clinic_branch.status_pending'.tr(),
        AppPalette.warning,
      ),
      ClinicBranchStatus.suspended => (
        'clinic_branch.status_suspended'.tr(),
        AppPalette.error,
      ),
    };

    return AppBadge.soft(label: label, color: color);
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
        Icon(icon, size: 18, color: AppPalette.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
