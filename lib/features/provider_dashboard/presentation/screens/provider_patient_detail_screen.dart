import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import '../../domain/entities/patient.dart';
import '../controllers/provider_dashboard_providers.dart';
import '../widgets/provider_appointment_card.dart';

class ProviderPatientDetailScreen extends ConsumerWidget {
  const ProviderPatientDetailScreen({required this.patient, super.key});

  final Patient patient;

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The list screen already paged the same ±90-day window over `GET
    // /v1/doctors/me/appointments` and grouped every appointment by
    // `patientId` while building the patient list — read that instead of
    // running a second, independent lookup here (the endpoint has no
    // `patientId` filter to query more narrowly anyway).
    final patientsDataAsync = ref.watch(providerPatientsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: Text('provider_dashboard.patients.detail_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Snapshot Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: brandBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: brandBlue, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    patient.patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.patientPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
              ),
            ),
            if (patient.nextAppointmentAt != null) ...[
              const SizedBox(height: 16),
              // Next Appointment Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: brandBlue, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'provider_dashboard.patients.next_appointment'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(patient.nextAppointmentAt!),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'provider_dashboard.patients.appointment_history'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            // Appointment History List
            AsyncValueView(
              value: patientsDataAsync,
              onRetry: () => ref.invalidate(providerPatientsDataProvider),
              data: (data) {
                final patientAppointments =
                    data.appointmentsByPatientId[patient.patientId] ??
                    const [];

                if (patientAppointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'provider_dashboard.patients.no_other_appointments'
                            .tr(),
                        style: const TextStyle(color: AppColors.mutedText2),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patientAppointments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final apt = patientAppointments[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_filled,
                            color: AppColors.mutedText2,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(apt.startAt.toLocal()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  apt.clinicName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            doctorAppointmentStatusStyle(apt.status).label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: brandBlue,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
