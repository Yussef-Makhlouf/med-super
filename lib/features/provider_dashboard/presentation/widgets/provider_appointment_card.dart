import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';

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
    final status = doctorAppointmentStatusStyle(appointment.status);
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
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
                              Icons.access_time,
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
              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    size: 14,
                    color: AppColors.mutedText2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${appointment.clinicName} · ${appointment.clinicCity}',
                      style: const TextStyle(
                        color: AppColors.mutedText2,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (appointment.isActionable &&
                  (onCancel != null || onReschedule != null)) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onReschedule != null)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: busy ? null : onReschedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                          height: 44,
                          child: OutlinedButton(
                            onPressed: busy ? null : onCancel,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF8FAFC),
                              foregroundColor: AppColors.errorRed,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
