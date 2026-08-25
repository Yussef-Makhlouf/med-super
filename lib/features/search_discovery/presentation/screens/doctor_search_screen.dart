import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
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
    context.push('/patient/doctors/$doctorId');
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: brandBlue),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: brandBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SortChips(
                  selected: params.sort,
                  onSelected: (sort) => ref
                      .read(doctorSearchControllerProvider.notifier)
                      .setSort(sort),
                ),
              ],
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
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: data.doctors.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'search.results_count'.tr(args: ['${data.totalCount}']),
                        style: textTheme.bodyMedium?.copyWith(color: _muted),
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
              borderRadius: BorderRadius.circular(22),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }
}
