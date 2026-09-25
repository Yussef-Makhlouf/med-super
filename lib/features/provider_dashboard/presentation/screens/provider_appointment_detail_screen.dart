import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/doctor_appointment_visit_action_policy.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_cancel_appointment_dialog.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_reschedule_sheet.dart';
import 'provider_clinical_requests_screen.dart';
import 'package:solar_icons/solar_icons.dart';

/// Opens [ProviderAppointmentDetailScreen] as a bottom sheet rather than a
/// full page route — consistent with every other provider-dashboard action
/// surface (walk-in booking, reschedule, add-branch). Resolves to `true` when
/// the appointment was mutated (cancelled/rescheduled), same contract the
/// screen itself used to return from `Navigator.pop`.
Future<bool?> showProviderAppointmentDetailSheet(
  BuildContext context, {
  required String appointmentId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceApp,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        ProviderAppointmentDetailScreen(appointmentId: appointmentId),
  );
}

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
  DoctorAppointment? _visitOverride;

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
    _visitOverride = null;
    ref.invalidate(doctorAppointmentDetailProvider(widget.appointmentId));
    ref.invalidate(doctorAppointmentsProvider);
  }

  Future<void> _advanceVisitStatus(DoctorAppointment appointment) async {
    final next = appointment.visitStatus.next;
    final availability = DoctorAppointmentVisitActionPolicy.standard.evaluate(
      appointment,
    );
    if (_mutating ||
        next == null ||
        availability != DoctorAppointmentVisitActionAvailability.available)
      return;

    setState(() => _mutating = true);
    final result = await ref
        .read(updateAppointmentVisitStatusUseCaseProvider)
        .call(
          appointmentId: appointment.appointmentId,
          status: next,
          version: appointment.version,
        );
    if (!mounted) return;

    result.when(
      ok: (updated) {
        setState(() {
          _mutating = false;
          _changed = true;
          _visitOverride = updated;
        });
        ref.invalidate(doctorAppointmentsProvider);
        _showSnack(
          'provider_dashboard.visit_status.updated'.tr(),
          success: true,
        );
      },
      err: (failure) {
        setState(() => _mutating = false);
        _showSnack(providerFailureMessage(failure));
        _refresh();
      },
    );
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
        // Same staleness as the walk-in sheet: the picked slot came from a
        // list fetched before this request landed, and may already be
        // BOOKED by the time it does (SLOT_ALREADY_BOOKED). Invalidate so
        // the next reschedule attempt on this branch shows a genuinely
        // current list instead of offering the same dead slot again.
        ref.invalidate(
          doctorOpenSlotsProvider((
            doctorId: doctorId,
            clinicBranchId: appointment.clinicBranchId,
            from: null,
            to: null,
          )),
        );
        _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      doctorAppointmentDetailProvider(widget.appointmentId),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'provider_dashboard.appointments.detail_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip:
                      MaterialLocalizations.of(context).closeButtonTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.mutedText2,
                    fixedSize: const Size(42, 42),
                  ),
                  icon: const Icon(SolarIconsOutline.closeCircle, size: 20),
                  onPressed: () => Navigator.of(context).pop(_changed),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView<DoctorAppointment>(
              value: async,
              onRetry: _refresh,
              data: (appointment) =>
                  _body(_visitOverride ?? appointment, scrollController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    DoctorAppointment appointment,
    ScrollController scrollController,
  ) {
    final status = doctorAppointmentStatusStyle(appointment.status);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 18, 28),
      children: [
        _card(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: brandBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    SolarIconsOutline.user,
                    color: brandBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appointment.patientName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.ink900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge.soft(label: status.label, color: status.color),
              ],
            ),
            const SizedBox(height: 12),
            _row(
              SolarIconsOutline.phone,
              'provider_dashboard.appointments.patient_phone'.tr(),
              appointment.patientPhone,
              valueDirection: TextDirection.ltr,
            ),
            _row(
              SolarIconsOutline.clockCircle,
              'provider_dashboard.appointments.appointment_time'.tr(),
              '${formatAppointmentTime(appointment.startAt)} – ${formatAppointmentTime(appointment.endAt)}',
            ),
            _row(
              SolarIconsOutline.buildings,
              'provider_dashboard.appointments.branch'.tr(),
              '${appointment.clinicCity} · ${appointment.clinicAddressLine1}',
            ),
            _row(
              SolarIconsOutline.globus,
              'provider_dashboard.clinics.timezone'.tr(),
              appointment.ianaTimezone,
            ),
            if (appointment.cancelledReason != null)
              _row(
                SolarIconsOutline.infoCircle,
                'provider_dashboard.status.cancelled'.tr(),
                appointment.cancelledReason!,
              ),
            if (appointment.rescheduledFromAppointmentId != null)
              _row(
                SolarIconsOutline.history,
                'provider_dashboard.status.rescheduled'.tr(),
                appointment.rescheduledFromAppointmentId!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _visitStatusPanel(appointment),
        const SizedBox(height: 14),
        if (appointment.isActionable && !appointment.canChangeBooking)
          Text(
            'provider_dashboard.visit_status.booking_locked'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.mutedText2,
            ),
          ),
        if (appointment.canChangeBooking) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _mutating
                        ? null
                        : () => _reschedule(appointment),
                    icon: const Icon(SolarIconsOutline.restart, size: 18),
                    label: Text(
                      'provider_dashboard.reschedule.action'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandBlue,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: brandBlue.withValues(alpha: 0.20),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: TextButton.icon(
                    onPressed: _mutating ? null : () => _cancel(appointment),
                    icon: const Icon(SolarIconsOutline.closeCircle, size: 18),
                    label: Text(
                      'provider_dashboard.cancel.action'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      backgroundColor: AppColors.errorRed.withValues(
                        alpha: 0.045,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (appointment.payment case final payment?) ...[
          const SizedBox(height: 18),
          _paymentCard(payment),
        ],
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProviderClinicalRequestsScreen(
                  patientId: appointment.patientId,
                  patientName: appointment.patientName,
                  appointmentId: appointment.appointmentId,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      SolarIconsOutline.documentMedicine,
                      color: brandBlue,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'provider_dashboard.clinical_requests.open'.tr(),
                      style: const TextStyle(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? SolarIconsOutline.altArrowLeft
                        : SolarIconsOutline.altArrowRight,
                    color: AppColors.mutedText2,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_mutating)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _visitStatusPanel(DoctorAppointment appointment) {
    final visual = doctorVisitStatusStyle(appointment.visitStatus);
    final next = appointment.visitStatus.next;
    final availability = DoctorAppointmentVisitActionPolicy.standard.evaluate(
      appointment,
    );
    final completed =
        availability == DoctorAppointmentVisitActionAvailability.terminal;
    final enabled =
        availability == DoctorAppointmentVisitActionAvailability.available &&
        !_mutating;
    final hint = switch (availability) {
      DoctorAppointmentVisitActionAvailability.available =>
        'provider_dashboard.visit_status.next_hint'.tr(),
      DoctorAppointmentVisitActionAvailability.terminal =>
        'provider_dashboard.visit_status.complete_hint'.tr(),
      DoctorAppointmentVisitActionAvailability.unavailable =>
        'provider_dashboard.visit_status.unavailable'.tr(),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(visual.icon, color: visual.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'provider_dashboard.visit_status.title'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DoctorVisitStatusBadge(status: appointment.visitStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 16),
          if (availability ==
                  DoctorAppointmentVisitActionAvailability.available ||
              completed)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: enabled
                    ? () => _advanceVisitStatus(appointment)
                    : null,
                icon: _mutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        completed
                            ? SolarIconsBold.checkCircle
                            : doctorVisitStatusStyle(next!).icon,
                      ),
                label: Text(
                  completed
                      ? 'provider_dashboard.visit_status.complete'.tr()
                      : next == DoctorVisitStatus.inDoctorRoom
                      ? 'provider_dashboard.visit_status.action_in_doctor_room'
                            .tr()
                      : 'provider_dashboard.visit_status.action_left'.tr(),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceMuted,
                  disabledForegroundColor: visual.color,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Fee / paid in advance / left to collect — so the doctor or assistant
  /// knows what to take from the patient at the visit.
  Widget _paymentCard(DoctorAppointmentPayment payment) {
    String money(num value) => payment.currency == 'EGP'
        ? '${value.toStringAsFixed(2)} ج.م'
        : '${value.toStringAsFixed(2)} ${payment.currency}';
    return _card(
      children: [
        Text(
          'provider_dashboard.appointments.payment_title'.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink900,
          ),
        ),
        _row(
          Icons.payments_outlined,
          'provider_dashboard.appointments.payment_method'.tr(),
          _paymentMethodLabel(payment.method),
        ),
        _row(
          Icons.receipt_long_outlined,
          'provider_dashboard.appointments.fee'.tr(),
          money(payment.fullAmount),
        ),
        _row(
          Icons.check_circle_outline,
          'provider_dashboard.appointments.paid_amount'.tr(),
          money(payment.paidAmount),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: payment.isFullyPaid
                ? const Color(0xFF10B981).withValues(alpha: 0.10)
                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  payment.isFullyPaid
                      ? 'provider_dashboard.appointments.fully_paid'.tr()
                      : 'provider_dashboard.appointments.remaining_balance'
                            .tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              if (!payment.isFullyPaid)
                Text(
                  money(payment.remainingBalance),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink900,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _paymentMethodLabel(String method) => switch (method) {
    'PAY_AT_CLINIC' =>
      'provider_dashboard.appointments.method_pay_at_clinic'.tr(),
    'INTERNAL_WALLET' =>
      'provider_dashboard.appointments.method_internal_wallet'.tr(),
    'FAWRY' => 'provider_dashboard.appointments.method_fawry'.tr(),
    'CARD' => 'provider_dashboard.appointments.method_card'.tr(),
    'MOBILE_WALLET' =>
      'provider_dashboard.appointments.method_mobile_wallet'.tr(),
    _ => method,
  };

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.borderSubtle),
      boxShadow: AppShadows.resting,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _row(
    IconData icon,
    String label,
    String value, {
    TextDirection? valueDirection,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mutedText2),
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
                textDirection: valueDirection,
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
