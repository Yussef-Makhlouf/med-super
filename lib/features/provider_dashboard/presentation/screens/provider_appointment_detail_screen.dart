import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/provider_dashboard_providers.dart';

class ProviderAppointmentDetailScreen extends ConsumerWidget {
  const ProviderAppointmentDetailScreen({required this.appointment, super.key});

  final Appointment appointment;

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  void _onAccept(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(acceptAppointmentUseCaseProvider);
    final result = await useCase.call(appointment.id);
    result.when(
      ok: (_) {
        ref.invalidate(appointmentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم قبول موعد ${appointment.patientName}')),
        );
        Navigator.of(context).pop();
      },
      err: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${failure.toString()}')),
        );
      },
    );
  }

  void _onReject(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(rejectAppointmentUseCaseProvider);
    final result = await useCase.call(appointment.id);
    result.when(
      ok: (_) {
        ref.invalidate(appointmentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم رفض موعد ${appointment.patientName}')),
        );
        Navigator.of(context).pop();
      },
      err: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${failure.toString()}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusText = switch (appointment.status) {
      AppointmentStatus.confirmed => 'مؤكد',
      AppointmentStatus.cancelled => 'ملغي',
      AppointmentStatus.completed => 'مكتمل',
      AppointmentStatus.pending => 'قيد الانتظار',
    };

    final statusColor = switch (appointment.status) {
      AppointmentStatus.confirmed => brandBlue,
      AppointmentStatus.cancelled => AppColors.errorRed,
      AppointmentStatus.completed => const Color(0xFF10B981),
      AppointmentStatus.pending => Colors.orange,
    };

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('تفاصيل الموعد'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: brandBlue.withValues(alpha: 0.1),
                    backgroundImage: appointment.patientAvatarUrl != null
                        ? NetworkImage(appointment.patientAvatarUrl!)
                        : null,
                    child: appointment.patientAvatarUrl == null
                        ? const Icon(Icons.person, color: brandBlue, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'رقم الملف: ${appointment.medId}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Appointment Metadata Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_month,
                    label: 'وقت الموعد البدء',
                    value: _formatDateTime(appointment.scheduledStart),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.access_time_filled,
                    label: 'وقت الموعد الانتهاء',
                    value: _formatDateTime(appointment.scheduledEnd),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'موقع الحضور',
                    value: appointment.locationStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Status History Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سجل حالة الموعد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryItem(
                    title: 'تم إنشاء الموعد',
                    subtitle: _formatDateTime(
                      appointment.scheduledStart.subtract(
                        const Duration(hours: 24),
                      ),
                    ),
                    isDone: true,
                  ),
                  _buildHistoryItem(
                    title: 'حالة الموعد الحالية: $statusText',
                    subtitle: _formatDateTime(appointment.scheduledStart),
                    isDone: true,
                    isLast: true,
                  ),
                ],
              ),
            ),
            if (appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton.filled(
                      label: 'قبول الموعد',
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      borderRadius: 16,
                      onPressed: () => _onAccept(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.outlined(
                      label: 'رفض الموعد',
                      foregroundColor: AppColors.errorRed,
                      borderRadius: 16,
                      onPressed: () => _onReject(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: brandBlue, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText2, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isDone ? brandBlue : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
            ),
          ],
        ),
      ],
    );
  }
}
