import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/patient.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patient_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// Provider Patients Screen matching mockup `patients.png`.
class ProviderPatientsScreen extends ConsumerStatefulWidget {
  const ProviderPatientsScreen({super.key});

  @override
  ConsumerState<ProviderPatientsScreen> createState() =>
      _ProviderPatientsScreenState();
}

class _ProviderPatientsScreenState
    extends ConsumerState<ProviderPatientsScreen> {
  int _selectedFilter = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  static const _filters = ['الكل', 'اليوم', 'هذا الأسبوع'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  String _getFilterParam() {
    return switch (_selectedFilter) {
      1 => 'today',
      2 => 'week',
      _ => 'all',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filterParam = _getFilterParam();
    final patientsAsync = ref.watch(
      patientsProvider(query: _searchQuery, filter: filterParam),
    );
    final unreadNotifsCount = ref
        .watch(doctorNotificationsProvider)
        .maybeWhen(
          data: (list) => list.where((n) => n.isUnread).length,
          orElse: () => 0,
        );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'قائمة المرضى',
            unreadNotificationsCount: unreadNotifsCount,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الملف (MED-1234)…',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                Row(
                  children: List.generate(_filters.length, (index) {
                    final selected = _selectedFilter == index;
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ChoiceChip(
                        label: Text(_filters[index]),
                        selected: selected,
                        selectedColor: const Color(0xFFCCFBF1),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = index),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFCCFBF1)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Section Title + Live Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'قائمة المرضى المؤكدين',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    patientsAsync.maybeWhen(
                      data: (items) => Text(
                        '${items.length} مرضى',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      orElse: () => Text(
                        '-- مرضى',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Patient Cards List via AsyncValueView
                AsyncValueView<List<Patient>>(
                  value: patientsAsync,
                  loadingWidget: const CardSkeletonList(count: 3),
                  onRetry: () => ref.invalidate(patientsProvider),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EmptyState(
                          title: 'لا يوجد مرضى',
                          subtitle: 'لم يتم العثور على مرضى يطابقون بحثك.',
                          icon: Icons.people_outline,
                        ),
                      );
                    }
                    return Column(
                      children: items.map((patient) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildPatientCard(patient),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final initials = patient.name.isNotEmpty
        ? patient.name.trim().split(' ').take(2).map((e) => e[0]).join(' ')
        : 'م';

    final dateTimeFormatted =
        '${patient.nextAppointment.day}/${patient.nextAppointment.month}/${patient.nextAppointment.year} - ${_formatTime(patient.nextAppointment)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderPatientDetailScreen(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patient.status,
                      style: const TextStyle(
                        color: Color(0xFF0D9488),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: AppColors.mutedText2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.medId,
                        style: const TextStyle(
                          color: AppColors.mutedText2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: brandBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateTimeFormatted,
                          style: const TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFCCFBF1).withValues(alpha: 0.5),
                backgroundImage: patient.avatarUrl != null
                    ? NetworkImage(patient.avatarUrl!)
                    : null,
                child: patient.avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
