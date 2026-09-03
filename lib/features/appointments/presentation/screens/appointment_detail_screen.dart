import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/entities/reschedule_target.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';

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
              style: const TextStyle(color: AppColors.errorRed),
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
      backgroundColor: AppColors.surfaceApp,
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
                color: AppColors.patientPrimary,
              ),
            ),
          ),
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward)),
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
    'CONFIRMED' => AppColors.patientPrimary,
    'CANCELLED' => AppColors.errorRed,
    'RESCHEDULED' => AppColors.ratingAmber,
    'COMPLETED' => AppColors.patientPrimary,
    'NO_SHOW' => AppColors.errorRed,
    _ => AppColors.mutedText,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.borderLight),
          ),
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
                            color: AppColors.ink900,
                          ),
                        ),
                        if (appt.doctorName.isNotEmpty)
                          Text(
                            'appointments.appointment_id'.tr(
                              args: [appt.appointmentId.substring(0, 8)],
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusPill(label: _statusLabel, color: _statusColor),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: AppFormatters.fullDate(startLocal, locale: locale),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time_outlined,
                label:
                    '${AppFormatters.time(startLocal, locale: locale)} – ${AppFormatters.time(endLocal, locale: locale)}',
              ),
              if (appt.clinicName.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: appt.clinicName,
                ),
              ],
              if (appt.clinicAddressLine1.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: [
                    appt.clinicAddressLine1,
                    appt.clinicCity,
                  ].where((s) => s.isNotEmpty).join('، '),
                ),
              ],
              if (appt.clinicPhone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.call_outlined, label: appt.clinicPhone),
              ],
            ],
          ),
        ),
        if (appt.status == 'CANCELLED' && appt.cancelledReason != null) ...[
          const SizedBox(height: 16),
          _NoteCard(
            icon: Icons.info_outline,
            color: AppColors.errorRed,
            text: 'appointments.detail_cancelled_reason'.tr(
              args: [_cancelledReasonLabel],
            ),
          ),
        ],
        if (appt.rescheduledFromAppointmentId != null) ...[
          const SizedBox(height: 16),
          _NoteCard(
            icon: Icons.history_outlined,
            color: AppColors.ratingAmber,
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
                    foregroundColor: AppColors.patientPrimary,
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
                    foregroundColor: AppColors.errorRed,
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
        Icon(icon, size: 18, color: AppColors.mutedText2),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.bodyText),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
