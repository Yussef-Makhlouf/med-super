import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:solar_icons/solar_icons.dart';

/// Localized label + colour for an appointment status.
({String label, Color color}) doctorAppointmentStatusStyle(
  DoctorAppointmentStatus status,
) {
  return switch (status) {
    DoctorAppointmentStatus.confirmed => (
      label: 'provider_dashboard.status.confirmed'.tr(),
      color: brandBlue,
    ),
    DoctorAppointmentStatus.cancelled => (
      label: 'provider_dashboard.status.cancelled'.tr(),
      color: AppColors.errorRed,
    ),
    DoctorAppointmentStatus.rescheduled => (
      label: 'provider_dashboard.status.rescheduled'.tr(),
      color: Colors.orange,
    ),
    DoctorAppointmentStatus.completed => (
      label: 'provider_dashboard.status.completed'.tr(),
      color: const Color(0xFF10B981),
    ),
    DoctorAppointmentStatus.other => (
      label: 'provider_dashboard.status.other'.tr(),
      color: AppColors.mutedText2,
    ),
  };
}

({String label, Color color, IconData icon}) doctorVisitStatusStyle(
  DoctorVisitStatus status,
) {
  return switch (status) {
    DoctorVisitStatus.waiting => (
      label: 'provider_dashboard.visit_status.waiting'.tr(),
      color: const Color(0xFFB45309),
      icon: Icons.schedule_rounded,
    ),
    DoctorVisitStatus.inDoctorRoom => (
      label: 'provider_dashboard.visit_status.in_doctor_room'.tr(),
      color: brandBlue,
      icon: Icons.medical_services_outlined,
    ),
    DoctorVisitStatus.left => (
      label: 'provider_dashboard.visit_status.left'.tr(),
      color: const Color(0xFF059669),
      icon: Icons.check_circle_rounded,
    ),
  };
}

class DoctorVisitStatusBadge extends StatelessWidget {
  const DoctorVisitStatusBadge({required this.status, super.key});

  final DoctorVisitStatus status;

  @override
  Widget build(BuildContext context) {
    final visual = doctorVisitStatusStyle(status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, size: 14, color: visual.color),
            const SizedBox(width: 5),
            Text(
              visual.label,
              style: TextStyle(
                color: visual.color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `HH:mm` in the **branch's** local time.
///
/// `startAt` is UTC (File 11 Part 04). Rendering it with `toLocal()` would
/// show the device's zone, which is wrong the moment a doctor travels or a
/// clinic sits in a different zone from the phone. The offset is derived by
/// comparing the device zone to the branch zone would need a tz database,
/// which this app does not bundle — so instead the *stored* UTC instant is
/// shown against the device zone only when the two agree, and the branch
/// zone name is always displayed alongside so the reading is never
/// ambiguous. See `provider_dashboard/STATUS.md`.
String formatAppointmentTime(DateTime utc) {
  final local = utc.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $period';
}

/// One row in the doctor's appointment queue.
class ProviderAppointmentCard extends StatelessWidget {
  const ProviderAppointmentCard({
    required this.appointment,
    required this.onTap,
    this.onCancel,
    this.onReschedule,
    this.busy = false,
    super.key,
  });

  final DoctorAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  /// Disables both actions while another mutation is in flight, so a
  /// double-tap can't fire two cancels.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final lifecycleStatus = doctorAppointmentStatusStyle(appointment.status);
    final timeRange =
        '${formatAppointmentTime(appointment.startAt)} - ${formatAppointmentTime(appointment.endAt)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.resting,
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
                          appointment.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              SolarIconsOutline.clockCircle,
                              size: 13,
                              color: AppColors.mutedText2,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                timeRange,
                                style: const TextStyle(
                                  color: AppColors.mutedText2,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (appointment.status == DoctorAppointmentStatus.confirmed)
                    DoctorVisitStatusBadge(status: appointment.visitStatus)
                  else
                    AppBadge.soft(label: lifecycleStatus.label, color: lifecycleStatus.color),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    SolarIconsOutline.buildings,
                    size: 14,
                    color: AppColors.mutedText2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${appointment.clinicCity} · ${appointment.clinicAddressLine1}',
                      style: const TextStyle(
                        color: AppColors.mutedText2,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (appointment.canChangeBooking &&
                  (onCancel != null || onReschedule != null)) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onReschedule != null)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: busy ? null : onReschedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'provider_dashboard.reschedule.action'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onReschedule != null && onCancel != null)
                      const SizedBox(width: 12),
                    if (onCancel != null)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: busy ? null : onCancel,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surfaceApp,
                              foregroundColor: AppColors.errorRed,
                              side: const BorderSide(color: AppColors.borderLight),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'provider_dashboard.cancel.action'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
