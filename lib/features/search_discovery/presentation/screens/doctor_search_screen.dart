import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/presentation/controllers/specialties_providers.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/staggered_reveal.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/presentation/controllers/search_providers.dart';
import 'package:med_super/features/search_discovery/presentation/widgets/doctor_result_card.dart';

/// Doctor search results — matches Figma RTL search screen.
class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({
    this.initialSpecialty,
    this.initialSpecialtyName,
    this.titleKey,
    super.key,
  });

  final String? initialSpecialty;

  /// Display name for [initialSpecialty], passed straight from the caller
  /// (e.g. the home screen's specialties row, using the real
  /// `GET /v1/specialties` name) — the specialty code is an opaque backend
  /// id and can no longer be reliably mapped back to a translation key like
  /// the old hardcoded 5-specialty catalog did.
  final String? initialSpecialtyName;
  final String? titleKey;

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  static const _pageBg = Color(0xFFF3F6FB);
  static const _muted = Color(0xFF8A94A6);

  late final TextEditingController _queryController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    Future.microtask(() {
      if (!mounted) return;
      final controller = ref.read(doctorSearchControllerProvider.notifier);
      controller.setQuery('');
      controller.setSpecialty(widget.initialSpecialty);
      controller.setSort(DoctorSort.topRated);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(doctorSearchControllerProvider.notifier).setQuery(value);
    });
  }

  void _openDoctor(String doctorId) {
    context.push('/patient/home/doctors/$doctorId');
  }

  String get _title {
    final key = widget.titleKey;
    if (key != null && key.isNotEmpty) return key.tr();
    final specialtyName = widget.initialSpecialtyName;
    if (specialtyName != null && specialtyName.isNotEmpty) {
      return specialtyName;
    }
    return 'search.title'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(doctorSearchControllerProvider);
    final results = ref.watch(doctorSearchResultsProvider);
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
          _title,
          style: textTheme.titleLarge?.copyWith(
            color: brandBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          StaggeredReveal(
            index: 0,
            child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _queryController,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'search.placeholder'.tr(),
                    hintStyle: const TextStyle(color: _muted),
                    prefixIcon: const Icon(Icons.search, color: _muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: const BorderSide(
                        color: brandBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Arriving with a specialty already fixed (tapped from the
                // home screen's specialties row) means the user has already
                // chosen what they want to see — showing the filter chips
                // here would let them silently drift off that specialty or
                // re-sort a single-specialty list they didn't ask to sort.
                // Both rows only make sense for the general, unfiltered
                // search entry point (typed into the search input).
                if (widget.initialSpecialty == null) ...[
                  const SizedBox(height: 12),
                  _SpecialtyChips(
                    selected: params.specialty,
                    onSelected: (specialty) => ref
                        .read(doctorSearchControllerProvider.notifier)
                        .setSpecialty(specialty),
                  ),
                  const SizedBox(height: 12),
                  _SortChips(
                    selected: params.sort,
                    onSelected: (sort) => ref
                        .read(doctorSearchControllerProvider.notifier)
                        .setSort(sort),
                  ),
                ],
              ],
            ),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: results,
              onRetry: () => ref.invalidate(doctorSearchResultsProvider),
              data: (data) {
                if (data.doctors.isEmpty) {
                  return EmptyState(
                    title: 'search.empty_title'.tr(),
                    subtitle: 'search.empty_subtitle'.tr(),
                    icon: Icons.search_off,
                  );
                }
                // 1 header row + N doctors + (1 load-more row only if the
                // backend actually said there's another page).
                final itemCount = data.doctors.length + 1 + (data.hasMore ? 1 : 0);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: itemCount,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'search.results_count'.tr(args: ['${data.totalCount}']),
                        style: textTheme.bodyMedium?.copyWith(color: _muted),
                      );
                    }
                    if (index == itemCount - 1 && data.hasMore) {
                      return Center(
                        child: data.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: () => ref
                                    .read(doctorSearchResultsProvider.notifier)
                                    .loadMore(),
                                child: Text('search.load_more'.tr()),
                              ),
                      );
                    }
                    final doctor = data.doctors[index - 1];
                    return DoctorResultCard(
                      doctor: doctor,
                      onTap: () => _openDoctor(doctor.id),
                      onBook: () => _openDoctor(doctor.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChips extends ConsumerWidget {
  const _SpecialtyChips({required this.selected, required this.onSelected});

  static const _muted = Color(0xFF8A94A6);

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(specialtiesProvider);
    final languageCode = context.locale.languageCode;

    return specialties.when(
      data: (items) => _buildChips(context, items, languageCode),
      loading: () => const SizedBox(height: 40),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildChips(
    BuildContext context,
    List<Specialty> items,
    String languageCode,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selected == null;
            return ChoiceChip(
              label: Text('search.specialty_all'.tr()),
              selected: isSelected,
              onSelected: (_) => onSelected(null),
              selectedColor: brandBlue.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? brandBlue : _muted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? brandBlue : const Color(0xFFE5EAF2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }
          final specialty = items[index - 1];
          final isSelected = specialty.code == selected;
          return ChoiceChip(
            label: Text(specialty.localizedName(languageCode)),
            selected: isSelected,
            onSelected: (_) => onSelected(specialty.code),
            selectedColor: brandBlue.withValues(alpha: 0.12),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? brandBlue : _muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: isSelected ? brandBlue : const Color(0xFFE5EAF2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  static const _muted = Color(0xFF8A94A6);

  final DoctorSort selected;
  final ValueChanged<DoctorSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(DoctorSort, String)>[
      (DoctorSort.topRated, 'search.sort_top_rated'),
      (DoctorSort.nearest, 'search.sort_nearest'),
      (DoctorSort.priceLowToHigh, 'search.sort_price'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (sort, key) = items[index];
          final isSelected = sort == selected;
          return ChoiceChip(
            label: Text(key.tr()),
            selected: isSelected,
            onSelected: (_) => onSelected(sort),
            selectedColor: brandBlue.withValues(alpha: 0.12),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? brandBlue : _muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: isSelected ? brandBlue : const Color(0xFFE5EAF2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }
}
