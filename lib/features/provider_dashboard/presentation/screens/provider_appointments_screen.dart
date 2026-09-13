import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/book_walkin_appointment_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_cancel_appointment_dialog.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// The doctor's appointment queue, backed by
/// `GET /v1/doctors/me/appointments` (File 12 Part 49.7).
///
/// The old accept/reject queue is gone: a real appointment is already
/// `CONFIRMED` when the doctor first sees it (the patient held the slot and
/// paid), so there is nothing to accept. The provider actions are **cancel**
/// and **reschedule**, both on the detail screen and inline here.
///
/// Paging is cursor-based and accumulated locally rather than through the
/// Riverpod family, because "load more" has to append to what is already on
/// screen; the family provider still owns the *first* page of every distinct
/// filter combination, and changing any filter resets the accumulator.
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
  static const _segmentStatuses = <DoctorAppointmentStatus>[
    DoctorAppointmentStatus.cancelled,
    DoctorAppointmentStatus.completed,
    DoctorAppointmentStatus.confirmed,
  ];

  late DateTime _selectedDate; // Today, until the doctor picks another date
  int _selectedSegment = 2; // Upcoming
  String? _branchId; // null = every branch the doctor works at

  final List<DoctorAppointment> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  Failure? _error;

  /// Guards against a double-tapped action firing two mutations.
  bool _mutating = false;

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

  DoctorAppointmentStatus get _selectedStatus =>
      _segmentStatuses[_selectedSegment];

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
          status: _selectedStatus,
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

  Future<void> _cancel(DoctorAppointment appointment) async {
    if (_mutating) return;
    final confirmed = await showProviderCancelDialog(
      context,
      patientName: appointment.patientName,
    );
    if (confirmed == null || !mounted) return;

    setState(() => _mutating = true);
    final result = await ref
        .read(cancelDoctorAppointmentUseCaseProvider)
        .call(appointmentId: appointment.appointmentId, note: confirmed.note);
    if (!mounted) return;
    setState(() => _mutating = false);

    result.when(
      ok: (outcome) {
        _showSnack(
          outcome.refundAmount > 0
              ? 'provider_dashboard.cancel.success_with_refund'.tr(
                  args: [outcome.refundAmount.toStringAsFixed(2), 'EGP'],
                )
              : 'provider_dashboard.cancel.success'.tr(),
          success: true,
        );
        _reload();
      },
      err: (failure) => _showSnack(providerFailureMessage(failure)),
    );
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
                  const SizedBox(height: 16),
                  _dayPicker(),
                  const SizedBox(height: 16),
                  clinicsAsync.maybeWhen(
                    data: _branchFilter,
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  _segments(),
                  const SizedBox(height: 20),
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
    final count = _items.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'provider_dashboard.appointments.summary_title'.tr(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'provider_dashboard.appointments.summary_count'.tr(
                    args: ['$count${_nextCursor != null ? '+' : ''}'],
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  _loading ? '--' : count.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: brandBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
                Text(
                  'provider_dashboard.appointments.summary_total'.tr(),
                  style: const TextStyle(
                    color: brandBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? brandBlue : const Color(0xFFF1F5F9),
                      ),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: AppColors.mutedText2),
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
    const labels = [
      'provider_dashboard.appointments.segment_cancelled',
      'provider_dashboard.appointments.segment_completed',
      'provider_dashboard.appointments.segment_upcoming',
    ];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedSegment == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterChanged(() => _selectedSegment = index),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _list() {
    if (_loading) return const CardSkeletonList(count: 2);

    final error = _error;
    if (error != null && _items.isEmpty) {
      return ErrorBanner(message: providerFailureMessage(error), onRetry: _reload);
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          title: 'provider_dashboard.appointments.empty_title'.tr(),
          subtitle: 'provider_dashboard.appointments.empty_subtitle'.tr(),
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    return Column(
      children: [
        for (final appointment in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ProviderAppointmentCard(
              appointment: appointment,
              busy: _mutating,
              onTap: () => _openDetail(appointment),
              onCancel: () => _cancel(appointment),
              onReschedule: () => _openDetail(appointment),
            ),
          ),
        if (_nextCursor != null)
          Padding(
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
          ),
      ],
    );
  }
}
