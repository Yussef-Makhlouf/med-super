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
    // The real queue is date-ranged and paginated. A patient's history is a
    // narrow read, so this asks for a wide window around today and filters
    // client-side — `GET /v1/doctors/me/appointments` has no patientId
    // filter, and inventing one on the client would not make it real.
    final now = DateTime.now();
    final appointmentsAsync = ref.watch(
      doctorAppointmentsProvider(
        from: now.subtract(const Duration(days: 90)),
        to: now.add(const Duration(days: 90)),
        limit: 50,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('الملف الطبي للمريض'),
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
                    backgroundImage: patient.avatarUrl != null
                        ? NetworkImage(patient.avatarUrl!)
                        : null,
                    child: patient.avatarUrl == null
                        ? const Icon(Icons.person, color: brandBlue, size: 36)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'رقم الملف (MED): ${patient.medId}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'الحالة: ${patient.status}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                        const Text(
                          'الموعد القادم',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(patient.nextAppointment),
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
            const SizedBox(height: 20),
            const Text(
              'سجل المواعيد للشيخ/المريض',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            // Appointment History List
            AsyncValueView(
              value: appointmentsAsync,
              onRetry: () => ref.invalidate(doctorAppointmentsProvider),
              data: (page) {
                final patientAppointments = page.items
                    .where(
                      (a) =>
                          a.patientId == patient.id ||
                          a.patientName.contains(patient.name) ||
                          patient.name.contains(a.patientName),
                    )
                    .toList();

                if (patientAppointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'لا توجد مواعيد مسجلة أخرى لهذا المريض',
                        style: TextStyle(color: AppColors.mutedText2),
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
