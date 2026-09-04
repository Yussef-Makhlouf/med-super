import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_cancel_appointment_dialog.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_reschedule_sheet.dart';

/// One appointment, read fresh from
/// `GET /v1/doctors/me/appointments/{id}` rather than passed in from the
/// list — so opening a detail after the list went stale shows the real
/// current state (and 404s honestly if the row is no longer the caller's).
///
/// Pops `true` when it mutated something, so the queue behind it knows to
/// refetch instead of refetching on every back-navigation.
class ProviderAppointmentDetailScreen extends ConsumerStatefulWidget {
  const ProviderAppointmentDetailScreen({
    required this.appointmentId,
    super.key,
  });

  final String appointmentId;

  @override
  ConsumerState<ProviderAppointmentDetailScreen> createState() =>
      _ProviderAppointmentDetailScreenState();
}

class _ProviderAppointmentDetailScreenState
    extends ConsumerState<ProviderAppointmentDetailScreen> {
  bool _mutating = false;
  bool _changed = false;

  void _showSnack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : null,
      ),
    );
  }

  void _refresh() {
    ref.invalidate(doctorAppointmentDetailProvider(widget.appointmentId));
  }

  Future<void> _cancel(DoctorAppointment appointment) async {
    if (_mutating) return;
    final decision = await showProviderCancelDialog(
      context,
      patientName: appointment.patientName,
    );
    if (decision == null || !mounted) return;

    setState(() => _mutating = true);
    final result = await ref
        .read(cancelDoctorAppointmentUseCaseProvider)
        .call(appointmentId: appointment.appointmentId, note: decision.note);
    if (!mounted) return;
    setState(() => _mutating = false);

    result.when(
      ok: (outcome) {
        _changed = true;
        _showSnack(
          outcome.refundAmount > 0
              ? 'provider_dashboard.cancel.success_with_refund'.tr(
                  args: [outcome.refundAmount.toStringAsFixed(2), 'EGP'],
                )
              : 'provider_dashboard.cancel.success'.tr(),
          success: true,
        );
        _refresh();
      },
      err: (failure) {
        _showSnack(providerFailureMessage(failure));
        // A 409/422 means our copy is stale — refetch so the buttons match
        // what the server will actually accept next time.
        _refresh();
      },
    );
  }

  Future<void> _reschedule(DoctorAppointment appointment) async {
    if (_mutating) return;

    final doctorId = ref
        .read(doctorAccountProvider)
        .maybeWhen(data: (account) => account.id, orElse: () => null);
    if (doctorId == null) {
      _showSnack('provider_dashboard.errors.generic'.tr());
      return;
    }

    final slotId = await showProviderRescheduleSheet(
      context,
      doctorId: doctorId,
      clinicBranchId: appointment.clinicBranchId,
      clinicName: appointment.clinicName,
    );
    if (slotId == null || !mounted) return;

    setState(() => _mutating = true);
    final result = await ref
        .read(rescheduleDoctorAppointmentUseCaseProvider)
        .call(appointmentId: appointment.appointmentId, newSlotId: slotId);
    if (!mounted) return;
    setState(() => _mutating = false);

    result.when(
      ok: (_) {
        _changed = true;
        _showSnack('provider_dashboard.reschedule.success'.tr(), success: true);
        // The move produced a *new* appointment id, so this screen's own row
        // is now RESCHEDULED. Pop back to the queue rather than showing a
        // terminal record with dead buttons.
        Navigator.of(context).pop(true);
      },
      err: (failure) {
        _showSnack(providerFailureMessage(failure));
        _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      doctorAppointmentDetailProvider(widget.appointmentId),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceApp,
        appBar: AppBar(
          title: Text('provider_dashboard.appointments.title'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: AsyncValueView<DoctorAppointment>(
          value: async,
          onRetry: _refresh,
          data: (appointment) => _body(appointment),
        ),
      ),
    );
  }

  Widget _body(DoctorAppointment appointment) {
    final status = doctorAppointmentStatusStyle(appointment.status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _card(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.patientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(
              Icons.phone_outlined,
              'provider_dashboard.appointments.patient_phone'.tr(),
              appointment.patientPhone,
            ),
            _row(
              Icons.access_time,
              'provider_dashboard.appointments.title'.tr(),
              '${formatAppointmentTime(appointment.startAt)} - ${formatAppointmentTime(appointment.endAt)}',
            ),
            _row(
              Icons.local_hospital_outlined,
              'provider_dashboard.appointments.branch'.tr(),
              '${appointment.clinicName} · ${appointment.clinicAddressLine1}, ${appointment.clinicCity}',
            ),
            _row(
              Icons.public,
              'provider_dashboard.clinics.timezone'.tr(),
              appointment.ianaTimezone,
            ),
            if (appointment.cancelledReason != null)
              _row(
                Icons.info_outline,
                'provider_dashboard.status.cancelled'.tr(),
                appointment.cancelledReason!,
              ),
            if (appointment.rescheduledFromAppointmentId != null)
              _row(
                Icons.history,
                'provider_dashboard.status.rescheduled'.tr(),
                appointment.rescheduledFromAppointmentId!,
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (appointment.isActionable) ...[
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _mutating ? null : () => _reschedule(appointment),
              icon: const Icon(Icons.event_repeat),
              label: Text('provider_dashboard.reschedule.action'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _mutating ? null : () => _cancel(appointment),
              icon: const Icon(Icons.cancel_outlined),
              label: Text('provider_dashboard.cancel.action'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
        if (_mutating)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText2),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
