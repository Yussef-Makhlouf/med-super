import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/clinic_providers.dart';

const _ink = Color(0xFF1A2B4A);
const _muted = Color(0xFF8A94A6);

/// Clinic details — `GET /v1/clinics/{clinicId}` (optional auth). Reuses
/// `DoctorDetailsScreen`'s card/section/design-system pieces (same
/// `_Card`/`_InfoChip` visual language, `brandBlue`/`AsyncValueView`) rather
/// than inventing new ones.
class ClinicDetailsScreen extends ConsumerWidget {
  const ClinicDetailsScreen({required this.clinicId, super.key});

  final String clinicId;

  static const _pageBg = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClinic = ref.watch(clinicProfileProvider(clinicId));

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
          'clinic_profile.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: AsyncValueView(
        value: asyncClinic,
        onRetry: () => ref.invalidate(clinicProfileProvider(clinicId)),
        data: (clinic) => _ClinicBody(clinic: clinic),
      ),
    );
  }
}

class _ClinicBody extends StatelessWidget {
  const _ClinicBody({required this.clinic});

  final ClinicProfile clinic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(clinic: clinic),
        const SizedBox(height: 12),
        if (clinic.branches.isEmpty)
          _Card(
            child: SizedBox(
              height: 64,
              child: Center(
                child: Text('clinic_profile.no_branches'.tr()),
              ),
            ),
          )
        else
          ...clinic.branches.map(
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
  const _HeaderCard({required this.clinic});

  final ClinicProfile clinic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isVerified = clinic.status == 'VERIFIED';
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
                  Icons.local_hospital_outlined,
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
                            clinic.brandName,
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
                      clinic.legalName,
                      style: textTheme.bodyMedium?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (clinic.regionCode != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.map_outlined,
                  label: clinic.regionCode!,
                ),
                _InfoChip(
                  icon: Icons.apartment_outlined,
                  label: 'clinic_profile.branch_count'.tr(
                    args: ['${clinic.branches.length}'],
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

  final ClinicBranchInfo branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // pushReplacement (not push): tapping this then tapping the branch
      // screen's own "view clinic" link back here would otherwise stack
      // clinic→branch→clinic→branch indefinitely. Replacing keeps this
      // clinic/branch pair's stack depth constant either direction.
      onTap: () =>
          context.pushReplacement('/patient/clinic-branches/${branch.id}'),
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
                        : 'clinic_profile.branch'.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      color: brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
