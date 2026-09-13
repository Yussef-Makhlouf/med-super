import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/entities/reschedule_target.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';

// ─── screen ───────────────────────────────────────────────────────────────────

/// Real Phase 4 `GET /v1/appointments` (File 12 Part 35.15/35.17) — patient-
/// only, cursor pagination not yet surfaced here (first page only; see
/// `lib/features/appointments/STATUS.md`). Cancel calls the real
/// `POST /v1/appointments/{id}/cancel`; reschedule pushes to
/// `RescheduleScreen`, which needs a doctorId it can only recover from a
/// mock-convention affiliationId — see that screen's doc comment and
/// `lib/features/appointments/STATUS.md` for the real-backend gap.
class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends ConsumerState<PatientAppointmentsScreen> {
  static const _pageBg = Color(0xFFF3F6FB);
  static const _muted = Color(0xFF8A94A6);

  int _selectedTab = 0; // 0 = upcoming, 1 = past
  String? _cancellingId;
  bool _navigatingToReschedule = false;

  Future<void> _cancel(AppointmentSummary appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('appointments.cancel_confirm_title'.tr()),
        content: Text('appointments.cancel_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('appointments.cancel_confirm_dismiss'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'appointments.cancel'.tr(),
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingId = appt.appointmentId);
    final result = await ref
        .read(cancelAppointmentUseCaseProvider)
        .call(appointmentId: appt.appointmentId, reason: 'PATIENT_REQUEST');
    if (!mounted) return;
    setState(() => _cancellingId = null);

    result.when(
      ok: (_) => ref.read(myAppointmentsRefreshProvider.notifier).state++,
      err: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('appointments.cancel_error'.tr()))),
    );
  }

  void _openDetail(AppointmentSummary appt) {
    context.push('/patient/home/appointments/${appt.appointmentId}');
  }

  Future<void> _reschedule(AppointmentSummary appt) async {
    // Guards against a double-tap (or a rebuild mid-navigation, e.g. from
    // an access-token refresh interleaving with the tap) firing
    // `context.push` twice for the same route — go_router then ends up
    // with two pages computing the same key in its stack at once, which
    // trips the framework's "!keyReservation.contains(key)" duplicate-page
    // assertion on the next frame.
    if (_navigatingToReschedule) return;
    setState(() => _navigatingToReschedule = true);
    await context.push(
      '/patient/home/appointments/reschedule',
      extra: RescheduleTarget(
        appointmentId: appt.appointmentId,
        doctorClinicAffiliationId: appt.doctorClinicAffiliationId,
        doctorId: appt.doctorId,
        currentStartAt: appt.startAt,
      ),
    );
    if (mounted) setState(() => _navigatingToReschedule = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : '';

    final asyncAppointments = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ApptHeader(displayName: displayName),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'appointments.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TabRow(
                selectedTab: _selectedTab,
                onTabChanged: (t) => setState(() => _selectedTab = t),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AsyncValueView(
                value: asyncAppointments,
                onRetry: () => ref.invalidate(myAppointmentsProvider),
                data: (state) {
                  // Upcoming = still confirmed; everything else (cancelled,
                  // rescheduled — the only other statuses this backend
                  // phase actually produces, File 12 Part 35.1) reads as
                  // "past" until a real completed/no-show status exists.
                  final appts = _selectedTab == 0
                      ? state.items.where((a) => a.status == 'CONFIRMED').toList()
                      : state.items.where((a) => a.status != 'CONFIRMED').toList();

                  if (appts.isEmpty) {
                    return Center(
                      child: Text(
                        'appointments.empty'.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: _muted),
                      ),
                    );
                  }

                  // Load-more only makes sense on the unfiltered end of the
                  // fetched page, so it's tacked onto whichever tab is
                  // active — the backend has no separate cursor per status
                  // filter here (File 12 Part 35.14 scopes cursor to the
                  // caller's whole list, not a client-side tab split).
                  final itemCount = appts.length + (state.hasMore ? 1 : 0);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      if (i == itemCount - 1 && state.hasMore) {
                        return Center(
                          child: state.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: CircularProgressIndicator(),
                                )
                              : TextButton(
                                  onPressed: () => ref
                                      .read(myAppointmentsProvider.notifier)
                                      .loadMore(),
                                  child: Text('appointments.load_more'.tr()),
                                ),
                        );
                      }
                      return _AppointmentCard(
                        appt: appts[i],
                        isCancelling: _cancellingId == appts[i].appointmentId,
                        isNavigatingToReschedule: _navigatingToReschedule,
                        onCancel: () => _cancel(appts[i]),
                        onReschedule: () => _reschedule(appts[i]),
                        onTap: () => _openDetail(appts[i]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header ───────────────────────────────────────────────────────────────────

class _ApptHeader extends ConsumerWidget {
  const _ApptHeader({required this.displayName});

  final String displayName;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

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
            backgroundColor: Color(0xFFDCE8FF),
            child: Icon(Icons.person, color: brandBlue),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'home.welcome'.tr(),
              style: textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            Text(
              displayName,
              style: textTheme.titleMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.go('/patient/notifications'),
          icon: Badge(
            smallSize: 8,
            backgroundColor: Colors.red,
            isLabelVisible: hasUnread,
            child: const Icon(Icons.notifications_outlined, color: _ink),
          ),
        ),
      ],
    );
  }
}

// ─── tabs ─────────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow({required this.selectedTab, required this.onTabChanged});

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _TabBtn(
            label: 'appointments.tab_upcoming'.tr(),
            isActive: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabBtn(
            label: 'appointments.tab_past'.tr(),
            isActive: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── appointment card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appt,
    required this.isCancelling,
    required this.isNavigatingToReschedule,
    required this.onCancel,
    required this.onReschedule,
    required this.onTap,
  });

  final AppointmentSummary appt;
  final bool isCancelling;
  final bool isNavigatingToReschedule;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onTap;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);
  static const _divider = Color(0xFFEFF2F7);

  Color get _statusColor => switch (appt.status) {
    'CONFIRMED' => brandBlue,
    'CANCELLED' => const Color(0xFFEF4444),
    'RESCHEDULED' => const Color(0xFFF59E0B),
    'COMPLETED' => brandBlue,
    'NO_SHOW' => const Color(0xFFEF4444),
    _ => _muted,
  };

  String get _statusLabel => switch (appt.status) {
    'CONFIRMED' => 'appointments.status_confirmed'.tr(),
    'CANCELLED' => 'appointments.status_cancelled'.tr(),
    'RESCHEDULED' => 'appointments.status_rescheduled'.tr(),
    'COMPLETED' => 'appointments.status_completed'.tr(),
    'HELD' => 'appointments.status_held'.tr(),
    'CHECKED_IN' => 'appointments.status_checked_in'.tr(),
    'IN_PROGRESS' => 'appointments.status_in_progress'.tr(),
    'NO_SHOW' => 'appointments.status_no_show'.tr(),
    'EXPIRED' => 'appointments.status_expired'.tr(),
    _ => appt.status,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final local = appt.startAt.toLocal();
    final locale = context.locale.languageCode;
    final dateLabel = AppFormatters.fullDate(local, locale: locale);
    final timeLabel = AppFormatters.time(local, locale: locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: brandBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.doctorName.isNotEmpty
                                ? appt.doctorName
                                : 'appointments.appointment_id'.tr(
                                    args: [appt.appointmentId.substring(0, 8)],
                                  ),
                            style: textTheme.titleMedium?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (appt.clinicName.isNotEmpty)
                            Text(
                              appt.clinicName,
                              style: textTheme.bodySmall?.copyWith(
                                color: _muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(label: _statusLabel, color: _statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: textTheme.bodySmall?.copyWith(color: _muted),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: textTheme.bodySmall?.copyWith(color: _muted),
                    ),
                  ],
                ),
                if (appt.isCancellable) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: _divider),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (isCancelling || isNavigatingToReschedule)
                              ? null
                              : onReschedule,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brandBlue,
                            side: const BorderSide(color: Color(0xFFC7D7FE)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text('appointments.reschedule'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCancelling ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('appointments.cancel'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
