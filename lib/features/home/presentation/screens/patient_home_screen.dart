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
        : null;

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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        children: [
                          StaggeredReveal(
                            index: 0,
                            child: _HomeHeader(displayName: displayName),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const StaggeredReveal(
                            index: 1,
                            child: _HomeSearchBar(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const StaggeredReveal(
                            index: 2,
                            child: _ServiceCarousel(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          StaggeredReveal(
                            index: 3,
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
                ),
              ),
              const SliverToBoxAdapter(
                child: StaggeredReveal(index: 6, child: _SpecialtiesRow()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StaggeredReveal(
                        index: 7,
                        child: SectionHeader(
                          title: 'home.featured_doctors'.tr(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: StaggeredReveal(
                        index: 8,
                        child: _FeaturedDoctorsList(),
                      ),
                    ),
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

  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;
    return Row(
      children: [
        IconButton(
          tooltip: 'nav.profile'.tr(),
          onPressed: () => context.go('/patient/profile'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const CircleAvatar(
            radius: 21,
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
              if (displayName != null)
                Text(
                  displayName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(color: AppPalette.ink),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'nav.notifications'.tr(),
          onPressed: () => context.go('/patient/notifications'),
          icon: Badge(
            smallSize: 8,
            backgroundColor: AppPalette.error,
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

class _ServiceCarousel extends ConsumerStatefulWidget {
  const _ServiceCarousel();

  @override
  ConsumerState<_ServiceCarousel> createState() => _ServiceCarouselState();
}

class _ServiceCarouselState extends ConsumerState<_ServiceCarousel> {
  final PageController _controller = PageController(viewportFraction: 1);
  int _activePage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final services = [
      _HomeService(
        title: 'home.find_doctor'.tr(),
        subtitle: 'home.find_doctor_sub'.tr(),
        image: 'assets/illustrations/doctor_discovery.png',
        cta: 'home.service_doctors_cta'.tr(),
        icon: SolarIconsOutline.stethoscope,
        onTap: () => context.push('/patient/home/search'),
      ),
      _HomeService(
        title: 'home.upload_rx'.tr(),
        subtitle: 'home.upload_rx_sub'.tr(),
        image: 'assets/illustrations/pharmacy_order.png',
        cta: 'home.service_pharmacy_cta'.tr(),
        icon: SolarIconsOutline.pills,
        onTap: () => _openPharmacy(context, ref),
      ),
      _HomeService(
        title: 'home.lab_service_title'.tr(),
        subtitle: 'home.lab_service_subtitle'.tr(),
        image: 'assets/illustrations/lab_service.png',
        cta: 'home.service_labs_cta'.tr(),
        icon: SolarIconsOutline.testTube,
        onTap: () => context.push('/patient/lab/upload'),
      ),
      _HomeService(
        title: 'nav.appointments'.tr(),
        subtitle: 'home.appointments_sub'.tr(),
        image: 'assets/illustrations/appointment_calendar.png',
        cta: 'home.service_appointments_cta'.tr(),
        icon: SolarIconsOutline.calendarMinimalistic,
        onTap: () => context.go('/patient/appointments'),
      ),
      _HomeService(
        title: 'home.wallet'.tr(),
        subtitle: 'home.wallet_sub'.tr(),
        image: 'assets/illustrations/wallet.png',
        cta: 'home.service_wallet_cta'.tr(),
        icon: SolarIconsOutline.walletMoney,
        onTap: () => context.push('/patient/home/wallet'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'home.services'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'home.swipe_services'.tr(),
              style: textTheme.labelSmall?.copyWith(color: AppPalette.inkMuted),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: AppPalette.inkMuted,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: textScale > 1.2 ? 240 : 204,
          child: PageView.builder(
            controller: _controller,
            itemCount: services.length,
            onPageChanged: (index) => setState(() => _activePage = index),
            itemBuilder: (context, index) => _HomeServiceCard(
              service: services[index],
              pageIndex: index,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(services.length, (index) {
            final active = index == _activePage;
            return Semantics(
              button: true,
              selected: active,
              label: services[index].title,
              child: SizedBox(
                width: 48,
                height: 48,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: active ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? AppPalette.primary
                            : AppPalette.border,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HomeService {
  const _HomeService({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.cta,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final String cta;
  final IconData icon;
  final VoidCallback onTap;
}

class _HomeServiceCard extends StatelessWidget {
  const _HomeServiceCard({required this.service, required this.pageIndex});

  final _HomeService service;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Semantics(
        button: true,
        label: '${service.title}. ${service.subtitle}. ${service.cta}',
        child: TapScale(
          onTap: service.onTap,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: pageIndex.isEven
                    ? const [Color(0xFF2452D9), Color(0xFF163BAA)]
                    : const [Color(0xFF126E75), Color(0xFF0C535F)],
              ),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.16),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final artWidth = constraints.maxWidth < 360 ? 112.0 : 142.0;
                return Stack(
                  children: [
                    PositionedDirectional(
                      end: -38,
                      top: -58,
                      child: IgnorePointer(
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: -3,
                      child: IgnorePointer(
                        child: Image.asset(
                          service.image,
                          width: artWidth,
                          height: 164,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        18,
                        15,
                        14,
                        14,
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth - artWidth - 34,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(service.icon, color: Colors.white, size: 23),
                            const SizedBox(height: 7),
                            Text(
                              service.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              service.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  12,
                                  7,
                                  8,
                                  7,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        service.cta,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: AppPalette.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AppPalette.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

void _openPharmacy(BuildContext context, WidgetRef ref) {
  ref.read(uploadedPrescriptionImagesProvider.notifier).clear();
  ref.read(selectedDeliveryMethodProvider.notifier).reset();
  ref.read(selectedPharmacyProvider.notifier).clear();
  ref.read(pharmacySearchQueryProvider.notifier).setQuery('');
  ref.invalidate(pharmacySearchProvider);
  ref.invalidate(prescriptionUploadControllerProvider);
  context.push('/patient/pharmacy/upload');
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
      height: 146,
      child: AsyncValueView(
        value: specialties,
        onRetry: () => ref.invalidate(specialtiesProvider),
        // Matches the loaded row's own shape (art tile + label) rather than a
        // generic spinner, so the layout doesn't jump once data arrives.
        loadingWidget: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(
            width: 98,
            child: Column(
              children: [
                SkeletonLoader(width: 82, height: 82, borderRadius: 24),
                SizedBox(height: 8),
                SkeletonLoader(width: 70, height: 12, borderRadius: 6),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppPalette.inkMuted),
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
    final illustration = specialtyIllustrationFor(specialty);
    final name = specialty.localizedName(context.locale.languageCode);
    return SizedBox(
      width: 98,
      child: TapScale(
        onTap: () => context.push(
          '/patient/home/search'
          '?specialty=${Uri.encodeComponent(specialty.code)}'
          '&title=${Uri.encodeComponent(name)}',
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                // Tinted with the specialty's own accent rather than flat
                // white, matching the visual mapping in specialty_visuals.dart.
                // instead of introducing a new one.
                color: visual.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.resting,
              ),
              clipBehavior: Clip.antiAlias,
              child: illustration == null
                  ? Center(
                      child: Icon(visual.icon, color: visual.color, size: 32),
                    )
                  : Image.asset(
                      illustration,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(visual.icon, color: visual.color, size: 32),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: AppPalette.ink,
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
