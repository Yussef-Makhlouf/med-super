import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/patient.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patient_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// Provider Patients Screen matching mockup `patients.png`.
///
/// The list is sourced from `providerPatientsProvider`, itself derived
/// purely from `GET /v1/doctors/me/appointments` (there is no dedicated
/// patients endpoint — see `STATUS.md`). Search is client-side over the
/// already-fetched deduped list, since the appointments endpoint has no
/// server-side patient search either. The "اليوم"/"هذا الأسبوع" chips filter
/// on [Patient.nextAppointmentAt] — a real field the shared use-case computes
/// from the same appointment set, not an invented one.
enum _PatientFilter { all, today, week }

class ProviderPatientsScreen extends ConsumerStatefulWidget {
  const ProviderPatientsScreen({super.key});

  @override
  ConsumerState<ProviderPatientsScreen> createState() =>
      _ProviderPatientsScreenState();
}

class _ProviderPatientsScreenState
    extends ConsumerState<ProviderPatientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  _PatientFilter _filter = _PatientFilter.all;

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

  List<Patient> _filtered(List<Patient> patients) {
    var result = patients;

    if (_filter != _PatientFilter.all) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final bound = _filter == _PatientFilter.today
          ? todayStart.add(const Duration(days: 1))
          : todayStart.add(const Duration(days: 7));
      result = result
          .where(
            (p) =>
                p.nextAppointmentAt != null &&
                !p.nextAppointmentAt!.isBefore(todayStart) &&
                p.nextAppointmentAt!.isBefore(bound),
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.patientName.toLowerCase().contains(q) ||
                p.patientPhone.toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final patientsAsync = ref.watch(providerPatientsProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationCountProvider);
    final avatarUrl = ref.watch(providerHeaderAvatarUrlProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'provider_dashboard.patients.title'.tr(),
            unreadNotificationsCount: unreadNotifsCount,
            avatarUrl: avatarUrl,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'provider_dashboard.patients.search_hint'.tr(),
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
                Row(
                  children: [
                    _buildFilterChip(
                      'provider_dashboard.patients.filter_all'.tr(),
                      _PatientFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'provider_dashboard.patients.filter_today'.tr(),
                      _PatientFilter.today,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'provider_dashboard.patients.filter_week'.tr(),
                      _PatientFilter.week,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'provider_dashboard.patients.title'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    patientsAsync.maybeWhen(
                      data: (items) => Text(
                        'provider_dashboard.patients.count'.tr(
                          args: [_filtered(items).length.toString()],
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      orElse: () => Text(
                        'provider_dashboard.patients.count_placeholder'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AsyncValueView<List<Patient>>(
                  value: patientsAsync,
                  loadingWidget: const CardSkeletonList(count: 3),
                  onRetry: () => ref.invalidate(providerPatientsProvider),
                  data: (items) {
                    final filtered = _filtered(items);
                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: EmptyState(
                          title: 'provider_dashboard.patients.empty_title'
                              .tr(),
                          subtitle:
                              'provider_dashboard.patients.empty_subtitle'
                                  .tr(),
                          icon: Icons.people_outline,
                        ),
                      );
                    }
                    return Column(
                      children: filtered.map((patient) {
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

  Widget _buildFilterChip(String label, _PatientFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.mutedText2,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      selectedColor: brandBlue,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? brandBlue : const Color(0xFFF1F5F9),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final initials = patient.patientName.isNotEmpty
        ? patient.patientName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e[0])
              .join(' ')
        : 'م';

    final nextAppointment = patient.nextAppointmentAt;
    final dateTimeFormatted = nextAppointment != null
        ? '${nextAppointment.day}/${nextAppointment.month}/${nextAppointment.year} - ${_formatTime(nextAppointment)}'
        : null;

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
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFCCFBF1).withValues(alpha: 0.5),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
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
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.mutedText2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patient.patientPhone,
                          style: const TextStyle(
                            color: AppColors.mutedText2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (dateTimeFormatted != null) ...[
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
                          mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
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
