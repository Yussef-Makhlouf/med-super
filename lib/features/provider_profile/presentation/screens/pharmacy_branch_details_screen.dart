import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/pharmacy_branch_providers.dart';

/// Public pharmacy-branch detail — `GET /v1/pharmacy-branches/{branchId}`
/// (optional auth). Card/section layout mirrors
/// `provider_profile/presentation/screens/doctor_details_screen.dart`, but
/// using the shared `AppColors`/`AppButton` design-system pieces (this
/// feature has no bespoke local color palette of its own).
///
/// A branch is the unit a patient browses and picks — there is no
/// "pharmacy chain" parent page to drill through first (a chain name alone
/// has no address/phone to act on), so this screen never links back up to
/// one.
class PharmacyBranchDetailsScreen extends ConsumerWidget {
  const PharmacyBranchDetailsScreen({
    required this.branchId,
    this.onSelect,
    super.key,
  });

  final String branchId;

  /// Set only when reached from `pharmacy_booking`'s select-a-branch step
  /// (via the route's `extra`) — shows a bottom "اختر والمتابعة" bar that
  /// marks this branch as chosen and advances the booking flow, so a
  /// patient can drill into the full profile before committing instead of
  /// only ever choosing from the compact list card. Null everywhere else
  /// (a plain "view branch" link), which renders the stub order CTA
  /// instead.
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBranch = ref.watch(pharmacyBranchProvider(branchId));

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.patientPrimary),
        ),
        title: Text(
          'pharmacy_branch.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.ink900,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: AsyncValueView(
        value: asyncBranch,
        onRetry: () => ref.invalidate(pharmacyBranchProvider(branchId)),
        data: (branch) => _BranchBody(branch: branch, showOrderCta: onSelect == null),
      ),
      bottomNavigationBar: onSelect == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'pharmacy_booking.select_pharmacy.choose_cta'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BranchBody extends StatelessWidget {
  const _BranchBody({required this.branch, required this.showOrderCta});

  final PharmacyBranch branch;
  final bool showOrderCta;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(branch: branch),
        const SizedBox(height: 12),
        _ContactCard(branch: branch),
        const SizedBox(height: 12),
        _AddressCard(branch: branch),
        if (showOrderCta) ...[
          const SizedBox(height: 20),
          AppButton.filled(
            label: 'pharmacy_branch.order_cta'.tr(),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('pharmacy_branch.order_soon'.tr())),
              );
            },
            fullWidth: true,
            backgroundColor: AppColors.patientPrimary,
            borderRadius: 14,
          ),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.branch});

  final PharmacyBranch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        children: [
          Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.surfaceMuted,
                child: Icon(
                  Icons.local_pharmacy_outlined,
                  size: 40,
                  color: AppColors.patientPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      branch.pharmacyName,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.patientPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (branch.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: AppColors.patientPrimary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (branch.deliveryCapable) ...[
            const SizedBox(height: 10),
            Container(
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
                  Text(
                    'pharmacy_branch.delivery_available'.tr(),
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.tealAccent,
                      fontWeight: FontWeight.w700,
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.branch});

  final PharmacyBranch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.patientPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'pharmacy_branch.contact'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.patientPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: AppFormatters.ltrIsolate(branch.phone),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: branch.ianaTimezone,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.branch});

  final PharmacyBranch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final address = branch.address;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.patientPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'pharmacy_branch.address'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.patientPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.line1,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.ink900),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.city}, ${address.regionCode}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedText2),
          ),
        ],
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
        Icon(icon, size: 18, color: AppColors.mutedText2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.ink900),
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
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }
}
