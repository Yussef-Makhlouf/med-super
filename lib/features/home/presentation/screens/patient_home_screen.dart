import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/presentation/controllers/specialties_providers.dart';
import 'package:med_super/core/specialties/presentation/utils/specialty_visuals.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/app_spacing.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/section_header.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/core/widgets/staggered_reveal.dart';
import 'package:med_super/core/widgets/tap_scale.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/home/presentation/controllers/featured_doctors_provider.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';
import 'package:med_super/features/search_discovery/presentation/widgets/doctor_result_card.dart';
import 'package:solar_icons/solar_icons.dart';

/// Patient home — "Warm Clinical" design system v2.
class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'أحمد محمد';

    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppPalette.primary,
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
                      const SizedBox(height: AppSpacing.lg),
                      const StaggeredReveal(index: 1, child: _HomeSearchBar()),
                      const SizedBox(height: AppSpacing.lg),
                      const StaggeredReveal(index: 2, child: _PromoBanner()),
                      const SizedBox(height: AppSpacing.lg),
                      const StaggeredReveal(index: 3, child: _QuickActions()),
                      const SizedBox(height: AppSpacing.xxl),
                      StaggeredReveal(
                        index: 4,
                        child: SectionHeader(
                          title: 'home.specialties'.tr(),
                          actionLabel: 'common.view_all'.tr(),
                          onAction: () =>
                              context.push('/patient/home/specialties'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: StaggeredReveal(index: 5, child: _SpecialtiesRow()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StaggeredReveal(
                    index: 6,
                    child: SectionHeader(title: 'home.featured_doctors'.tr()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
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

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/patient/profile'),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AppPalette.primarySoft,
            child: Icon(SolarIconsBold.userRounded, color: AppPalette.primary),
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
                  color: AppPalette.inkMuted,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(color: AppPalette.ink),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/patient/notifications'),
          icon: Badge(
            smallSize: 8,
            backgroundColor: Colors.red,
            isLabelVisible: hasUnread,
            child: const Icon(
              Icons.notifications_outlined,
              color: AppPalette.ink,
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
        hintStyle: const TextStyle(color: AppPalette.inkFaint),
        prefixIcon: const Icon(
          SolarIconsOutline.magnifier,
          color: AppPalette.inkMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
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
        // stop (the brand accent) must resolve to that same logical edge in
        // every locale (a physical `Alignment.centerRight` matched `ar` by
        // coincidence but broke contrast in `en`).
        gradient: const LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [AppPalette.primary, Color(0xFF4AA3F5), Color(0xFFB8D9FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.22),
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
          // placeholder. This gives the banner an actual visual identity (a
          // lab-test icon, matching `promo_title`'s "labs" copy and the
          // testTube icon already used for the same action in
          // `_QuickActions`), pinned to the gradient's palest stop — the
          // opposite edge from the white headline — so it never competes
          // with the text for contrast.
          PositionedDirectional(
            end: -28,
            top: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.16,
                child: Icon(
                  SolarIconsBold.testTube,
                  size: 148,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppBadge.filled(
                  label: 'home.special_offer'.tr(),
                  color: AppPalette.success,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'home.promo_title'.tr(),
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
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
                    foregroundColor: AppPalette.primary,
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
    // Match the tallest card (wallet's Arabic subtitle wraps to two lines)
    // so the three tiles stay the same height side by side.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              onTap: () => context.push('/patient/home/wallet'),
            ),
          ),
        ],
      ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppPalette.inkMuted,
              ),
            ),
          ],
        ),
      ),
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
                  const Icon(
                    SolarIconsOutline.stethoscope,
                    size: 28,
                    color: AppPalette.inkFaint,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'home.specialties_empty'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkMuted,
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
              style: textTheme.labelMedium?.copyWith(color: AppPalette.ink),
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
