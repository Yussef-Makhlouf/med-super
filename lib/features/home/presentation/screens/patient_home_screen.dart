import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
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
        onPressed: () {},
        backgroundColor: const Color(0xFFE11D48),
        child: const Icon(Icons.emergency, color: Colors.white),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _HomeHeader(displayName: displayName),
                    const SizedBox(height: 16),
                    const _HomeSearchBar(),
                    const SizedBox(height: 16),
                    const _PromoBanner(),
                    const SizedBox(height: 16),
                    const _QuickActions(),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'home.specialties'.tr(),
                      actionLabel: 'common.view_all'.tr(),
                      onAction: () => context.push('/patient/search'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SpecialtiesRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                  title: 'home.nearby_doctors'.tr(),
                  actionLabel: 'home.view_map'.tr(),
                  onAction: () => context.push('/patient/search'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: _mockDoctors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _DoctorCard(doctor: _mockDoctors[index]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
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
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFDCE8FF),
          child: Icon(Icons.person, color: brandBlue),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'home.welcome'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: PatientHomeScreen._muted,
              ),
            ),
            Text(
              displayName,
              style: textTheme.titleMedium?.copyWith(
                color: PatientHomeScreen._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.push('/patient/search'),
          icon: const Icon(Icons.search, color: PatientHomeScreen._ink),
        ),
        IconButton(
          onPressed: () {},
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
      onTap: () => context.push('/patient/search'),
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
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
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
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF1E6FE8), Color(0xFF4AA3F5), Color(0xFFB8D9FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: brandBlue.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
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
                    borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(12),
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
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(false),
            const SizedBox(width: 6),
            _dot(true),
            const SizedBox(width: 6),
            _dot(false),
          ],
        ),
      ],
    );
  }

  static Widget _dot(bool active) => Container(
    width: active ? 8 : 6,
    height: active ? 8 : 6,
    decoration: BoxDecoration(
      color: active ? brandBlue : const Color(0xFFD0D7E2),
      shape: BoxShape.circle,
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
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
            onTap: () => context.push('/patient/pharmacy/upload'),
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
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 28),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: brandBlue,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: PatientHomeScreen._ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SpecialtiesRow extends StatelessWidget {
  const _SpecialtiesRow();

  static final _items = <({IconData icon, Color color, String key, int count})>[
    (
      icon: Icons.favorite,
      color: const Color(0xFFEF4444),
      key: 'specialties.cardio',
      count: 120,
    ),
    (
      icon: Icons.child_care,
      color: const Color(0xFF06B6D4),
      key: 'specialties.pediatrics',
      count: 85,
    ),
    (
      icon: Icons.spa_outlined,
      color: const Color(0xFF14B8A6),
      key: 'specialties.dermatology',
      count: 64,
    ),
    (
      icon: Icons.medical_services_outlined,
      color: brandBlue,
      key: 'specialties.dental',
      count: 98,
    ),
    (
      icon: Icons.visibility_outlined,
      color: const Color(0xFFF97316),
      key: 'specialties.ophthalmology',
      count: 42,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return SizedBox(
            width: 78,
            child: InkWell(
              onTap: () => context.push(
                '/patient/search?specialty=${item.key.split('.').last}',
              ),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.key.tr(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: PatientHomeScreen._ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'home.doctors_count'.tr(args: ['${item.count}']),
                    style: textTheme.labelSmall?.copyWith(
                      color: PatientHomeScreen._muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final _Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availabilityColor = doctor.today
        ? const Color(0xFF16A34A)
        : brandBlue;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => context.push('/patient/doctors/${doctor.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: textTheme.labelMedium?.copyWith(
                            color: const Color(0xFFEA580C),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.push('/patient/doctors/${doctor.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'home.book'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      doctor.name,
                      style: textTheme.titleSmall?.copyWith(
                        color: PatientHomeScreen._ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${doctor.price} LE',
                          style: textTheme.labelMedium?.copyWith(
                            color: PatientHomeScreen._muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: PatientHomeScreen._muted,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${doctor.distanceKm} km',
                          style: textTheme.labelMedium?.copyWith(
                            color: PatientHomeScreen._muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: PatientHomeScreen._muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: availabilityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor.today
                            ? 'home.available_today'.tr(
                                args: [doctor.timeLabel],
                              )
                            : 'home.available_tomorrow'.tr(
                                args: [doctor.timeLabel],
                              ),
                        style: textTheme.labelSmall?.copyWith(
                          color: availabilityColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 32,
                backgroundColor: doctor.avatarColor,
                child: Text(
                  doctor.initials,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Doctor {
  const _Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.distanceKm,
    required this.price,
    required this.rating,
    required this.timeLabel,
    required this.today,
    required this.initials,
    required this.avatarColor,
  });

  final String id;
  final String name;
  final String specialty;
  final double distanceKm;
  final int price;
  final double rating;
  final String timeLabel;
  final bool today;
  final String initials;
  final Color avatarColor;
}

const _mockDoctors = [
  _Doctor(
    id: 'doc-sara',
    name: 'د. سارة المنصور',
    specialty: 'استشاري طب الأطفال',
    distanceKm: 2.5,
    price: 300,
    rating: 4.8,
    timeLabel: '06:00 م',
    today: true,
    initials: 'س',
    avatarColor: Color(0xFF7C3AED),
  ),
  _Doctor(
    id: 'doc-mahmoud',
    name: 'د. محمود حامد',
    specialty: 'استشاري جراحة القلب',
    distanceKm: 4.2,
    price: 500,
    rating: 4.9,
    timeLabel: '10:00 ص',
    today: false,
    initials: 'م',
    avatarColor: Color(0xFF0EA5E9),
  ),
];
