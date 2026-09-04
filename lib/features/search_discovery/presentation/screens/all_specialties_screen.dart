import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/presentation/controllers/specialties_providers.dart';
import 'package:med_super/core/specialties/presentation/utils/specialty_visuals.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';

/// Full "all categories" grid, reached from the patient home screen's
/// specialties row via "عرض الكل" — previously that link just opened
/// [DoctorSearchScreen] with no specialty filter, so the full catalog had
/// no dedicated screen at all. Reuses the same `specialtiesProvider` and
/// `specialtyVisualForCode` the home row already uses (`GET /v1/specialties`
/// — public, no auth), so no new data layer is needed.
class AllSpecialtiesScreen extends ConsumerWidget {
  const AllSpecialtiesScreen({super.key});

  static const _pageBg = Color(0xFFF3F6FB);
  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(specialtiesProvider);
    final textTheme = Theme.of(context).textTheme;

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
          'home.specialties'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: brandBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AsyncValueView(
          value: specialties,
          onRetry: () => ref.invalidate(specialtiesProvider),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'home.specialties_empty'.tr(),
                  style: textTheme.bodyMedium?.copyWith(color: _muted),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _CategoryTile(specialty: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.specialty});

  final Specialty specialty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = specialtyVisualForCode(specialty.code);
    final name = specialty.localizedName(context.locale.languageCode);

    return InkWell(
      onTap: () => context.push(
        '/patient/home/search'
        '?specialty=${Uri.encodeComponent(specialty.code)}'
        '&title=${Uri.encodeComponent(name)}',
      ),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Icon(visual.icon, color: visual.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AllSpecialtiesScreen._ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
