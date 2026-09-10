import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/presentation/controllers/specialties_providers.dart';
import 'package:med_super/core/specialties/presentation/utils/specialty_visuals.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/core/widgets/staggered_reveal.dart';
import 'package:med_super/core/widgets/tap_scale.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/home/presentation/controllers/featured_doctors_provider.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';
import 'package:med_super/features/search_discovery/presentation/widgets/doctor_result_card.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_dashboard_screen.dart';

/// Patient home — matches Figma light dashboard.
class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  static const _pageBg = Color(0xFFF3F6FB);
  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'أحمد محمد';

    return Scaffold(
      backgroundColor: _pageBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        // Explicit heroTag — otherwise this collides with any other FAB
        // using Flutter's shared default tag (e.g. provider_home_screen.dart's)
        // during a route transition that has both on screen at once.
        heroTag: 'patient_home_fab',
        onPressed: () {},
        backgroundColor: const Color(0xFFE11D48),
        child: const Icon(Icons.emergency, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(specialtiesProvider.future),
            ref.refresh(featuredDoctorsProvider.future),
          ]),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      StaggeredReveal(
                        index: 0,
                        child: _HomeHeader(displayName: displayName),
                      ),
                      const SizedBox(height: 16),
                      const StaggeredReveal(index: 1, child: _HomeSearchBar()),
                      const SizedBox(height: 16),
                      const StaggeredReveal(index: 2, child: _PromoBanner()),
                      const SizedBox(height: 16),
                      const StaggeredReveal(index: 3, child: _QuickActions()),
                      const SizedBox(height: 24),
                      StaggeredReveal(
                        index: 4,
                        child: _SectionHeader(
                          title: 'home.specialties'.tr(),
                          actionLabel: 'common.view_all'.tr(),
                          onAction: () =>
                              context.push('/patient/home/specialties'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: StaggeredReveal(index: 5, child: _SpecialtiesRow()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StaggeredReveal(
                    index: 6,
                    child: _SectionHeader(title: 'home.featured_doctors'.tr()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: const SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 7,
                    child: _FeaturedDoctorsList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/patient/profile'),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFDCE8FF),
            child: Icon(Icons.person, color: brandBlue),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'home.welcome'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: PatientHomeScreen._muted,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: PatientHomeScreen._ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/patient/notifications'),
          icon: const Badge(
            smallSize: 8,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.notifications_outlined,
              color: PatientHomeScreen._ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () => context.push('/patient/home/search'),
      decoration: InputDecoration(
        hintText: 'home.search_hint'.tr(),
        hintStyle: const TextStyle(color: PatientHomeScreen._muted),
        prefixIcon: const Icon(Icons.search, color: PatientHomeScreen._muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        // `AlignmentDirectional`, not physical `Alignment` — the white
        // headline below sits at `centerStart`, so the gradient's darkest
        // stop (brandBlue) must resolve to that same logical edge in every
        // locale. With a physical `Alignment.centerRight` this matched by
        // coincidence in `ar` (start == right) but put the white text over
        // the palest stop (#B8D9FF) in `en` — a contrast failure.
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [brandBlue, const Color(0xFF4AA3F5), const Color(0xFFB8D9FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // `Clip.antiAlias` so the watermark icon below is clipped to the same
      // rounded corners as the banner itself, rather than poking past them.
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // A flat gradient card with text on it isn't a hero — it's a
          // placeholder (design-taste-frontend skill, 4.8). This gives the
          // banner an actual visual identity (a lab-test icon, matching
          // `promo_title`'s "labs" copy and the `biotech_outlined` icon
          // already used for the same action on `_QuickActions`), pinned to
          // the gradient's palest stop — the opposite edge from the white
          // headline — so it never competes with the text for contrast.
          PositionedDirectional(
            end: -28,
            top: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.16,
                child: Icon(Icons.biotech, size: 148, color: Colors.white),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    'home.special_offer'.tr(),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'home.promo_title'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'home.promo_subtitle'.tr(),
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton(
                  onPressed: () => context.push('/patient/lab/upload'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brandBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                  child: Text(
                    'home.book_now'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.biotech_outlined,
            iconColor: brandBlue,
            title: 'home.book_labs'.tr(),
            subtitle: 'home.book_labs_sub'.tr(),
            onTap: () => context.push('/patient/lab/upload'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.upload_file_outlined,
            iconColor: const Color(0xFF14B8A6),
            title: 'home.upload_rx'.tr(),
            subtitle: 'home.upload_rx_sub'.tr(),
            onTap: () {
              ref.read(uploadedPrescriptionImagesProvider.notifier).clear();
              ref.read(selectedDeliveryMethodProvider.notifier).reset();
              ref.read(selectedPharmacyProvider.notifier).clear();
              ref.read(pharmacySearchQueryProvider.notifier).setQuery('');
              ref.invalidate(pharmacySearchProvider);
              ref.invalidate(prescriptionUploadControllerProvider);
              context.push('/patient/pharmacy/upload');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: brandBlue,
            title: 'home.wallet'.tr(),
            subtitle: 'home.wallet_sub'.tr(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(
                  name: WalletDashboardScreen.routeName,
                ),
                builder: (_) => const WalletDashboardScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.resting,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: PatientHomeScreen._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: PatientHomeScreen._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction})
    : assert(
        (actionLabel == null) == (onAction == null),
        'actionLabel and onAction must both be set or both be omitted',
      );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: brandBlue,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        const Spacer(),
        // A small accent bar ahead of the title reads as hierarchy (this is
        // a section start) rather than ornament, and costs nothing visually
        // busy. It's built as a nested `Row` — not a `Positioned`/hardcoded
        // side — so it sits at the title's logical start (right before it
        // in reading order) in both `en` and `ar` automatically.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: brandBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: PatientHomeScreen._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Real `GET /v1/specialties` list (public, no auth) — replaces the
/// previously hardcoded 5-item catalog. Icons/colors are still client-side
/// (the backend carries no visual metadata for a specialty), resolved via
/// [specialtyVisualForCode]; the display name and the code used to filter
/// search now come straight from the API response.
class _SpecialtiesRow extends ConsumerWidget {
  const _SpecialtiesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(specialtiesProvider);
    return SizedBox(
      height: 118,
      child: AsyncValueView(
        value: specialties,
        onRetry: () => ref.invalidate(specialtiesProvider),
        // Matches the loaded row's own shape (circle + label) rather than a
        // generic spinner, so the layout doesn't jump once data arrives.
        loadingWidget: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(
            width: 78,
            child: Column(
              children: [
                SkeletonLoader(width: 64, height: 64, borderRadius: 32),
                SizedBox(height: 8),
                SkeletonLoader(width: 48, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 28,
                    color: PatientHomeScreen._muted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'home.specialties_empty'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PatientHomeScreen._muted,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _SpecialtyItem(specialty: items[index]),
          );
        },
      ),
    );
  }
}

class _SpecialtyItem extends StatelessWidget {
  const _SpecialtyItem({required this.specialty});

  final Specialty specialty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = specialtyVisualForCode(specialty.code);
    final name = specialty.localizedName(context.locale.languageCode);
    return SizedBox(
      width: 78,
      child: TapScale(
        onTap: () => context.push(
          '/patient/home/search'
          '?specialty=${Uri.encodeComponent(specialty.code)}'
          '&title=${Uri.encodeComponent(name)}',
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                // Tinted with the specialty's own icon color rather than
                // flat white — reinforces the per-specialty color coding
                // already carried by the icon (see specialty_visuals.dart)
                // instead of introducing a new one.
                color: visual.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: AppShadows.resting,
              ),
              child: Icon(visual.icon, color: visual.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: PatientHomeScreen._ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedDoctorsList extends ConsumerWidget {
  const _FeaturedDoctorsList();

  void _openDoctor(BuildContext context, String doctorId) =>
      context.push('/patient/home/doctors/$doctorId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(featuredDoctorsProvider);
    return AsyncValueView(
      value: doctors,
      onRetry: () => ref.invalidate(featuredDoctorsProvider),
      data: (list) => Column(
        children: [
          for (final doctor in list) ...[
            DoctorResultCard(
              doctor: doctor,
              onTap: () => _openDoctor(context, doctor.id),
              onBook: () => _openDoctor(context, doctor.id),
            ),
            if (doctor != list.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
