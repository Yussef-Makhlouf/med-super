import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/entities/reschedule_target.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:solar_icons/solar_icons.dart';

/// `GET /v1/appointments/{id}` (File 12 Part 35.17), read-only detail view
/// for one appointment plus its cancel/reschedule actions — the same
/// actions `PatientAppointmentsScreen`'s list card offers, since this
/// backend phase exposes nothing on the detail response that the list
/// summary doesn't already have (no doctor name/specialty — see
/// `lib/features/appointments/STATUS.md`). Reached by tapping a card in
/// `PatientAppointmentsScreen`.
class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  bool _cancelling = false;
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
              style: const TextStyle(color: AppPalette.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final result = await ref
        .read(cancelAppointmentUseCaseProvider)
        .call(appointmentId: appt.appointmentId, reason: 'PATIENT_REQUEST');
    if (!mounted) return;
    setState(() => _cancelling = false);

    result.when(
      ok: (_) => ref.read(myAppointmentsRefreshProvider.notifier).state++,
      err: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('appointments.cancel_error'.tr()))),
    );
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
    final asyncAppt = ref.watch(
      appointmentDetailProvider(widget.appointmentId),
    );

    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: AsyncValueView(
                value: asyncAppt,
                onRetry: () => ref.invalidate(
                  appointmentDetailProvider(widget.appointmentId),
                ),
                data: (appt) => _DetailBody(
                  appt: appt,
                  isCancelling: _cancelling,
                  isNavigatingToReschedule: _navigatingToReschedule,
                  onCancel: () => _cancel(appt),
                  onReschedule: () => _reschedule(appt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'appointments.detail_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(SolarIconsOutline.arrowRight),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.appt,
    required this.isCancelling,
    required this.isNavigatingToReschedule,
    required this.onCancel,
    required this.onReschedule,
  });

  final AppointmentSummary appt;
  final bool isCancelling;
  final bool isNavigatingToReschedule;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  Color get _statusColor => switch (appt.status) {
    'CONFIRMED' => AppPalette.primary,
    'CANCELLED' => AppPalette.error,
    'RESCHEDULED' => AppPalette.warning,
    'COMPLETED' => AppPalette.primary,
    'NO_SHOW' => AppPalette.error,
    _ => AppPalette.inkMuted,
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

  String get _cancelledReasonLabel => switch (appt.cancelledReason) {
    'PATIENT_REQUEST' => 'appointments.cancel_reason_patient_request'.tr(),
    'PROVIDER_REQUEST' => 'appointments.cancel_reason_provider_request'.tr(),
    'OTHER' => 'appointments.cancel_reason_other'.tr(),
    _ => appt.cancelledReason ?? '',
  };

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final startLocal = appt.startAt.toLocal();
    final endLocal = appt.endAt.toLocal();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.ink,
                          ),
                        ),
                        if (appt.doctorName.isNotEmpty)
                          Text(
                            'appointments.appointment_id'.tr(
                              args: [appt.appointmentId.substring(0, 8)],
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppPalette.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppBadge.soft(
                    label: _statusLabel,
                    color: _statusColor,
                    bordered: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppPalette.border),
              const SizedBox(height: 14),
              _InfoRow(
                icon: SolarIconsOutline.calendarMinimalistic,
                label: AppFormatters.fullDate(startLocal, locale: locale),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: SolarIconsOutline.clockCircle,
                label:
                    '${AppFormatters.time(startLocal, locale: locale)} – ${AppFormatters.time(endLocal, locale: locale)}',
              ),
              if (appt.clinicName.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: SolarIconsOutline.hospital,
                  label: appt.clinicName,
                ),
              ],
              if (appt.clinicAddressLine1.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: SolarIconsOutline.mapPoint,
                  label: [
                    appt.clinicAddressLine1,
                    appt.clinicCity,
                  ].where((s) => s.isNotEmpty).join('، '),
                ),
              ],
              if (appt.clinicPhone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: SolarIconsOutline.phone,
                  label: appt.clinicPhone,
                ),
              ],
            ],
          ),
        ),
        if (appt.status == 'CANCELLED' && appt.cancelledReason != null) ...[
          const SizedBox(height: 16),
          _NoteCard(
            icon: SolarIconsOutline.infoCircle,
            color: AppPalette.error,
            text: 'appointments.detail_cancelled_reason'.tr(
              args: [_cancelledReasonLabel],
            ),
          ),
        ],
        if (appt.rescheduledFromAppointmentId != null) ...[
          const SizedBox(height: 16),
          _NoteCard(
            icon: SolarIconsOutline.history,
            color: AppPalette.warning,
            text: 'appointments.detail_rescheduled_from'.tr(
              args: [appt.rescheduledFromAppointmentId!.substring(0, 8)],
            ),
          ),
        ],
        if (appt.isCancellable) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (isCancelling || isNavigatingToReschedule)
                      ? null
                      : onReschedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.primary,
                    side: BorderSide(
                      color: AppPalette.primary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
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
                    foregroundColor: AppPalette.error,
                    side: BorderSide(
                      color: AppPalette.error.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('appointments.cancel'.tr()),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.inkMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppPalette.ink),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}
