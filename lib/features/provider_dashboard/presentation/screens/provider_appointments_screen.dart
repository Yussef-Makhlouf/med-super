import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/book_walkin_appointment_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// Daily visit-workflow board, backed by the doctor's scoped appointments.
/// The home tab is the availability calendar; this tab helps the clinic move
/// confirmed patients through waiting → in-room → left and review the visit
/// record. Booking changes remain in the detail sheet.
class ProviderAppointmentsScreen extends ConsumerStatefulWidget {
  const ProviderAppointmentsScreen({this.openAppointmentId, super.key});

  /// Set when this screen was reached via a notification tap
  /// (`?openAppointmentId=...` on the route) — opens that appointment's
  /// detail sheet automatically once the screen is built.
  final String? openAppointmentId;

  @override
  ConsumerState<ProviderAppointmentsScreen> createState() =>
      _ProviderAppointmentsScreenState();
}

class _ProviderAppointmentsScreenState
    extends ConsumerState<ProviderAppointmentsScreen> {
  late DateTime _selectedDate; // Today, until the doctor picks another date
  int _selectedVisitStage = 0;
  bool _historyMode = false;
  String? _branchId; // null = every branch the doctor works at

  final List<DoctorAppointment> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  Failure? _error;

  // Tracks which notification-provided appointment id has already triggered
  // the auto-open, so a rebuild of this screen (tab switch, go_router
  // re-evaluating the route, a parent StatefulShellBranch restore) never
  // reopens the same sheet a second time — `didUpdateWidget` alone isn't
  // enough since `widget.openAppointmentId` doesn't change across those
  // rebuilds, only `initState` would normally fire once, but a route
  // re-entry with the same query param can still recreate this State.
  String? _autoOpenedAppointmentId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _maybeAutoOpenFromNotification();
    });
  }

  void _maybeAutoOpenFromNotification() {
    final appointmentId = widget.openAppointmentId;
    if (appointmentId == null ||
        appointmentId.isEmpty ||
        appointmentId == _autoOpenedAppointmentId) {
      return;
    }
    _autoOpenedAppointmentId = appointmentId;
    _openAppointmentFromNotification(appointmentId);
  }

  Future<void> _openAppointmentFromNotification(String appointmentId) async {
    if (!mounted) return;
    final mutated = await showProviderAppointmentDetailSheet(
      context,
      appointmentId: appointmentId,
    );
    if (mutated == true) _reload();
  }

  /// The 5-day quick-pick strip, always centered two days behind and two
  /// days ahead of [_selectedDate] — so jumping to any date via the calendar
  /// picker re-centers the strip on it instead of leaving the picked date
  /// off-strip and unreachable by tapping.
  List<DateTime> get _strip => [
    for (var offset = -2; offset <= 2; offset++)
      _selectedDate.add(Duration(days: offset)),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _onFilterChanged(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
  }

  /// Local midnight-to-midnight. The backend applies **both** bounds, so this
  /// is a real single-day window rather than "everything up to tomorrow".
  ({DateTime from, DateTime to}) get _dayRange {
    final from = _selectedDate;
    return (from: from, to: from.add(const Duration(days: 1)));
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _nextCursor = null;
    });
    await _fetch(cursor: null);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    await _fetch(cursor: _nextCursor);
  }

  Future<void> _fetch({required String? cursor}) async {
    final range = _dayRange;
    final result = await ref
        .read(getDoctorAppointmentsUseCaseProvider)
        .call(
          from: range.from,
          to: range.to,
          status: _historyMode ? null : DoctorAppointmentStatus.confirmed,
          clinicBranchId: _branchId,
          cursor: cursor,
        );
    if (!mounted) return;

    result.when(
      ok: (page) => setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loading = false;
        _loadingMore = false;
        _error = null;
      }),
      err: (failure) => setState(() {
        _loading = false;
        _loadingMore = false;
        _error = failure;
      }),
    );
  }

  void _onFilterChanged(VoidCallback apply) {
    setState(apply);
    _reload();
  }

  Future<void> _openDetail(DoctorAppointment appointment) async {
    await showProviderAppointmentDetailSheet(
      context,
      appointmentId: appointment.appointmentId,
    );
    // A bottom sheet can be dismissed by swipe/backdrop-tap as well as its
    // own close button, so the mutated-or-not result isn't reliable — always
    // refetch on close instead of trusting the returned value.
    if (mounted) await _reload();
  }

  Future<void> _openBookWalkIn() async {
    // `doctorAccountProvider` is `autoDispose`, so if nothing else on screen
    // is watching it right when the FAB is tapped, a stale `.read` here can
    // see it re-fetching from scratch instead of the cached value — wait for
    // the in-flight future rather than failing immediately on a transient
    // loading state.
    final String doctorId;
    try {
      doctorId = (await ref.read(doctorAccountProvider.future)).id;
    } catch (_) {
      if (mounted) _showSnack('provider_dashboard.errors.generic'.tr());
      return;
    }
    if (!mounted) return;

    final booked = await showBookWalkInAppointmentSheet(
      context,
      doctorId: doctorId,
    );
    if (booked == true && mounted) {
      _showSnack('provider_dashboard.walk_in.success'.tr(), success: true);
      await _reload();
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clinicsAsync = ref.watch(myClinicsProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationCountProvider);
    final avatarUrl = ref.watch(providerHeaderAvatarUrlProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBookWalkIn,
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text('provider_dashboard.appointments.add_walk_in'.tr()),
      ),
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'provider_dashboard.appointments.title'.tr(),
            unreadNotificationsCount: unreadNotifsCount,
            avatarUrl: avatarUrl,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _summaryTile(textTheme),
                  const SizedBox(height: 18),
                  _dayPicker(),
                  const SizedBox(height: 12),
                  clinicsAsync.maybeWhen(
                    data: _branchFilter,
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  _workspaceMode(),
                  const SizedBox(height: 12),
                  _segments(),
                  const SizedBox(height: 14),
                  _list(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(TextTheme textTheme) {
    String countLabel(int count) => '$count${_nextCursor == null ? '' : '+'}';

    final appointments = _items
        .where((item) => item.status == DoctorAppointmentStatus.confirmed)
        .toList();
    final history = _items
        .where((item) => item.status != DoctorAppointmentStatus.confirmed)
        .toList();
    final waiting = appointments
        .where((item) => item.visitStatus == DoctorVisitStatus.waiting)
        .length;
    final inRoom = appointments
        .where((item) => item.visitStatus == DoctorVisitStatus.inDoctorRoom)
        .length;
    final dateLabel = DateFormat.yMMMMEEEEd(
      context.locale.toString(),
    ).format(_selectedDate);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [brandBlue, brandBlue.withValues(alpha: 0.86)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (_historyMode
                    ? 'provider_dashboard.appointments.history_title'
                    : 'provider_dashboard.appointments.workflow_title')
                .tr(),
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loading
                          ? '—'
                          : countLabel(
                              _historyMode ? history.length : appointments.length,
                            ),
                      style: const TextStyle(
                        color: brandBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'provider_dashboard.appointments.metric_total'.tr(),
                      style: const TextStyle(
                        color: brandBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _inlineSummaryMetric(
                      label: (_historyMode
                              ? 'provider_dashboard.appointments.metric_cancelled'
                              : 'provider_dashboard.appointments.metric_waiting')
                          .tr(),
                      value: _loading
                          ? '—'
                          : _historyMode
                          ? countLabel(
                              history
                                  .where((item) => item.status == DoctorAppointmentStatus.cancelled)
                                  .length,
                            )
                          : countLabel(waiting),
                      icon: _historyMode
                          ? Icons.event_busy_outlined
                          : SolarIconsOutline.clockCircle,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 24),
                      child: Divider(
                        height: 12,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    _inlineSummaryMetric(
                      label: (_historyMode
                              ? 'provider_dashboard.appointments.metric_completed'
                              : 'provider_dashboard.appointments.metric_in_room')
                          .tr(),
                      value: _loading
                          ? '—'
                          : _historyMode
                          ? countLabel(
                              history
                                  .where((item) => item.status == DoctorAppointmentStatus.completed)
                                  .length,
                            )
                          : countLabel(inRoom),
                      icon: _historyMode
                          ? Icons.check_circle_outline
                          : Icons.medical_services_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inlineSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 19,
          height: 1.1,
        ),
      ),
    ],
  );

  Widget _workspaceMode() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _historyMode
                ? 'provider_dashboard.appointments.history_title'.tr()
                : 'provider_dashboard.appointments.visit_flow_title'.tr(),
            style: const TextStyle(
              color: AppColors.ink900,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _onFilterChanged(() {
            _historyMode = !_historyMode;
            _selectedVisitStage = 0;
          }),
          icon: Icon(
            _historyMode ? Icons.arrow_back_rounded : Icons.history_rounded,
            size: 18,
          ),
          label: Text(
            _historyMode
                ? 'provider_dashboard.appointments.back_to_visits'.tr()
                : 'provider_dashboard.appointments.open_history'.tr(),
          ),
        ),
      ],
    );
  }

  Widget _dayPicker() {
    final dates = _strip;
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final selected = date == _selectedDate;
                return GestureDetector(
                  onTap: () => _onFilterChanged(() => _selectedDate = date),
                  child: Container(
                    width: 62,
                    margin: const EdgeInsetsDirectional.only(end: 10),
                    decoration: BoxDecoration(
                      color: selected ? brandBlue : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.borderLight),
                      boxShadow: selected ? AppShadows.resting : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'provider_dashboard.weekday.${date.weekday}'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.mutedText2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: 48,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(SolarIconsOutline.calendar, color: AppColors.mutedText2),
            ),
          ),
        ],
      ),
    );
  }

  /// Only rendered when the doctor actually works at more than one branch —
  /// a single-branch doctor gets no useless filter.
  Widget _branchFilter(List<DoctorClinic> clinics) {
    if (clinics.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _branchChip(
            label: Text(
              'provider_dashboard.appointments.all_branches'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            selected: _branchId == null,
            onTap: () => _onFilterChanged(() => _branchId = null),
          ),
          for (final clinic in clinics)
            _branchChip(
              // Branches have no name of their own, and two branches of the
              // same clinic share clinicName — the city is what actually
              // tells them apart (same convention as the clinics list/
              // schedule-editor branch picker/home-screen branch tabs), with
              // the street address as a muted subtitle underneath.
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.address.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    Text(
                      clinic.address.line1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                    ),
                  ],
                ),
              ),
              selected: _branchId == clinic.clinicBranchId,
              onTap: () => _onFilterChanged(
                () => _branchId = clinic.clinicBranchId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _branchChip({
    required Widget label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: label,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _segments() {
    if (_historyMode) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.mutedText2),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'provider_dashboard.appointments.history_hint'.tr(),
                style: const TextStyle(
                  color: AppColors.mutedText2,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    const labels = [
      'provider_dashboard.appointments.visit_all',
      'provider_dashboard.visit_status.waiting',
      'provider_dashboard.visit_status.in_doctor_room',
      'provider_dashboard.visit_status.left',
    ];
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = _selectedVisitStage == index;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                onTap: () => setState(() => _selectedVisitStage = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? brandBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    boxShadow: selected ? AppShadows.resting : null,
                  ),
                  child: Center(
                    child: Text(
                      labels[index].tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.mutedText2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<DoctorAppointment> get _visibleItems {
    final rows = _historyMode
        ? _items.where((item) => item.status != DoctorAppointmentStatus.confirmed)
        : _items.where((item) => item.status == DoctorAppointmentStatus.confirmed);
    final filtered = rows.where((item) {
      if (_historyMode || _selectedVisitStage == 0) return true;
      return switch (_selectedVisitStage) {
        1 => item.visitStatus == DoctorVisitStatus.waiting,
        2 => item.visitStatus == DoctorVisitStatus.inDoctorRoom,
        3 => item.visitStatus == DoctorVisitStatus.left,
        _ => true,
      };
    }).toList();
    // Most recent first.
    filtered.sort((a, b) => b.startAt.compareTo(a.startAt));
    return filtered;
  }

  Widget _list() {
    if (_loading) return const CardSkeletonList(count: 2);

    final error = _error;
    if (error != null && _items.isEmpty) {
      return ErrorBanner(message: providerFailureMessage(error), onRetry: _reload);
    }

    final visibleItems = _visibleItems;
    if (visibleItems.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
              title: _historyMode
                  ? 'provider_dashboard.appointments.history_empty_title'.tr()
                  : 'provider_dashboard.appointments.stage_empty_title'.tr(),
              subtitle: _historyMode
                  ? 'provider_dashboard.appointments.history_empty_subtitle'.tr()
                  : 'provider_dashboard.appointments.stage_empty_subtitle'.tr(),
              icon: SolarIconsOutline.calendarMinimalistic,
            ),
          ),
          if (_nextCursor != null) _loadMoreButton(),
        ],
      );
    }

    return Column(
      children: [
        for (final appointment in visibleItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _appointmentCard(appointment),
          ),
        if (_nextCursor != null) _loadMoreButton(),
      ],
    );
  }

  Widget _loadMoreButton() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    child: OutlinedButton(
      onPressed: _loadingMore ? null : _loadMore,
      child: _loadingMore
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text('provider_dashboard.appointments.load_more'.tr()),
    ),
  );

  Widget _appointmentCard(DoctorAppointment appointment) {
    final active = appointment.status == DoctorAppointmentStatus.confirmed;
    final payment = appointment.payment;
    final remaining = payment?.remainingBalance ?? 0;
    final status = doctorAppointmentStatusStyle(
      appointment.status,
      statusCode: appointment.statusCode,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: () => _openDetail(appointment),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.resting,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      children: [
                        Text(
                          formatAppointmentTime(appointment.startAt),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink900,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatAppointmentTime(appointment.endAt),
                          style: const TextStyle(
                            color: AppColors.mutedText2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink900,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appointment.patientPhone,
                          textDirection: ui.TextDirection.ltr,
                          style: const TextStyle(
                            color: AppColors.mutedText2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (active)
                    DoctorVisitStatusBadge(status: appointment.visitStatus)
                  else
                    AppBadge.soft(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(
                    SolarIconsOutline.mapPoint,
                    size: 16,
                    color: AppColors.mutedText2,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${appointment.clinicCity} · ${appointment.clinicAddressLine1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (active && payment != null && remaining > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'provider_dashboard.appointments.balance_due'.tr(),
                          style: const TextStyle(
                            color: AppColors.ink900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${remaining.toStringAsFixed(2)} ${payment.currency}',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    'provider_dashboard.appointments.open_visit'.tr(),
                    style: const TextStyle(
                      color: brandBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Directionality.of(context) == ui.TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                    color: brandBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
