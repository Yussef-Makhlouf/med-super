import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/pharmacy_providers.dart';

const _ink = Color(0xFF1A2B4A);
const _muted = Color(0xFF8A94A6);

/// Pharmacy details — `GET /v1/pharmacies/{pharmacyId}` (optional auth).
/// Reuses `DoctorDetailsScreen`/`ClinicDetailsScreen`'s card/section/design
/// -system pieces (same `_Card`/`_InfoChip` visual language, `brandBlue`/
/// `AsyncValueView`) rather than inventing new ones.
class PharmacyDetailsScreen extends ConsumerWidget {
  const PharmacyDetailsScreen({
    required this.pharmacyId,
    this.onSelect,
    super.key,
  });

  final String pharmacyId;

  /// Set only when reached from `pharmacy_booking`'s select-a-pharmacy step
  /// (via the route's `extra`) — shows a bottom "اختر والمتابعة" bar that
  /// marks this pharmacy as chosen and advances the booking flow, so a
  /// patient can drill into the full profile before committing instead of
  /// only ever choosing from the compact list card. Null everywhere else
  /// (a plain "view pharmacy" link), which renders exactly as before.
  final VoidCallback? onSelect;

  static const _pageBg = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPharmacy = ref.watch(pharmacyProfileProvider(pharmacyId));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: brandBlue),
        ),
        title: Text(
          'pharmacy_profile.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: AsyncValueView(
        value: asyncPharmacy,
        onRetry: () => ref.invalidate(pharmacyProfileProvider(pharmacyId)),
        data: (pharmacy) => _PharmacyBody(pharmacy: pharmacy),
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
                      backgroundColor: brandBlue,
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

class _PharmacyBody extends StatelessWidget {
  const _PharmacyBody({required this.pharmacy});

  final PharmacyProfile pharmacy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(pharmacy: pharmacy),
        const SizedBox(height: 12),
        if (pharmacy.branches.isEmpty)
          _Card(
            child: SizedBox(
              height: 64,
              child: Center(child: Text('pharmacy_profile.no_branches'.tr())),
            ),
          )
        else
          ...pharmacy.branches.map(
            (branch) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BranchCard(branch: branch),
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.pharmacy});

  final PharmacyProfile pharmacy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isVerified = pharmacy.status == 'VERIFIED';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFDCE8FF),
                child: Icon(
                  Icons.local_pharmacy_outlined,
                  size: 28,
                  color: brandBlue,
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
                            pharmacy.brandName,
                            style: textTheme.titleLarge?.copyWith(
                              color: brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isVerified) ...[
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
                      pharmacy.legalName,
                      style: textTheme.bodyMedium?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pharmacy.regionCode != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.map_outlined, label: pharmacy.regionCode!),
                _InfoChip(
                  icon: Icons.apartment_outlined,
                  label: 'pharmacy_profile.branch_count'.tr(
                    args: ['${pharmacy.branches.length}'],
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

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});

  final PharmacyBranchInfo branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // pushReplacement (not push): see the matching comment on
      // ClinicDetailsScreen's branch-card onTap — avoids an ever-growing
      // pharmacy→branch→pharmacy→branch stack.
      onTap: () =>
          context.pushReplacement('/patient/pharmacy-branches/${branch.id}'),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: brandBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.address.city.isNotEmpty
                        ? branch.address.city
                        : 'pharmacy_profile.branch'.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      color: brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (branch.deliveryCapable)
                  _InfoChip(
                    icon: Icons.local_shipping_outlined,
                    label: 'pharmacy_profile.delivery_capable'.tr(),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: _muted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.location_on_outlined,
              text: branch.address.line1,
            ),
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.phone_outlined,
              text: AppFormatters.ltrIsolate(branch.phone),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.schedule_outlined,
              text: branch.ianaTimezone,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _ink.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}
