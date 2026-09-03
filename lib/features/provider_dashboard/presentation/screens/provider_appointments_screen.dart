import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/appointment.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/add_appointment_bottom_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

/// Provider Dashboard / Appointments Queue Screen matching `dashboard_header.png`.
/// This is the original "المواعيد" tab design — day picker + status segments +
/// accept/reject queue — kept as-is while the Home tab was redesigned into a
/// calendar (see provider_home_screen.dart).
class ProviderAppointmentsScreen extends ConsumerStatefulWidget {
  const ProviderAppointmentsScreen({super.key});

  @override
  ConsumerState<ProviderAppointmentsScreen> createState() =>
      _ProviderAppointmentsScreenState();
}

class _ProviderAppointmentsScreenState
    extends ConsumerState<ProviderAppointmentsScreen> {
  int _selectedDayIndex = 1; // Default selected: Today
  int _selectedSegment = 2; // Default: القادمة (Upcoming)

  late final List<DateTime> _dates;
  static const _segments = ['الملغاة', 'المنتهية', 'القادمة'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = [
      now.subtract(const Duration(days: 1)),
      now,
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 2)),
      now.add(const Duration(days: 3)),
    ];
  }

  String _getStatusParam() {
    return switch (_selectedSegment) {
      0 => 'cancelled',
      1 => 'completed',
      _ => 'pending,confirmed',
    };
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return dayNames[date.weekday - 1];
  }

  void _onAccept(Appointment appointment) async {
    final useCase = ref.read(acceptAppointmentUseCaseProvider);
    final result = await useCase.call(appointment.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(appointmentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قبول موعد ${appointment.patientName}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
      err: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  void _onReject(Appointment appointment) async {
    final useCase = ref.read(rejectAppointmentUseCaseProvider);
    final result = await useCase.call(appointment.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(appointmentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض موعد ${appointment.patientName}'),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () => _onAccept(appointment),
            ),
          ),
        );
      },
      err: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  void _openAddAppointment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAppointmentBottomSheet(
        onAdd: (patientName, startTime, endTime) async {
          final useCase = ref.read(createAppointmentUseCaseProvider);
          final result = await useCase.call(
            patientName: patientName,
            scheduledStart: startTime,
            scheduledEnd: endTime,
          );
          if (!mounted) return;
          result.when(
            ok: (_) {
              ref.invalidate(appointmentsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت إضافة الموعد بنجاح'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            err: (failure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(failure.toString())));
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedDate = _dates[_selectedDayIndex];
    final statusParam = _getStatusParam();

    final appointmentsAsync = ref.watch(
      appointmentsProvider(date: selectedDate, status: statusParam),
    );
    final unreadNotifsCount = ref
        .watch(doctorNotificationsProvider)
        .maybeWhen(
          data: (list) => list.where((n) => n.isUnread).length,
          orElse: () => 0,
        );

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      floatingActionButton: FloatingActionButton(
        // Explicit heroTag — otherwise this collides with any other FAB
        // using Flutter's shared default tag (e.g. patient_home_screen.dart's)
        // during a route transition that has both on screen at once.
        heroTag: 'provider_appointments_fab',
        onPressed: _openAddAppointment,
        backgroundColor: brandBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'لوحة التحكم',
            unreadNotificationsCount: unreadNotifsCount,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Today's Appointments Summary Tile
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مواعيد اليوم',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          appointmentsAsync.maybeWhen(
                            data: (list) => Text(
                              'لديك ${list.length} مواعيد مجدولة',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedText2,
                              ),
                            ),
                            orElse: () => Text(
                              'لديك مواعيد مجدولة اليوم',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedText2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: brandBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              appointmentsAsync.maybeWhen(
                                data: (list) =>
                                    list.length.toString().padLeft(2, '0'),
                                orElse: () => '--',
                              ),
                              style: const TextStyle(
                                color: brandBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'إجمالي',
                              style: TextStyle(
                                color: brandBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Horizontally Scrollable Day Picker
                SizedBox(
                  height: 76,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (context, index) {
                      final date = _dates[index];
                      final selected = _selectedDayIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: Container(
                          width: 62,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: selected ? brandBlue : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? brandBlue
                                  : const Color(0xFFF1F5F9),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppColors.mutedText2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.ink900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // 3-Way Segmented Tab Row
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: List.generate(_segments.length, (index) {
                      final selected = _selectedSegment == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSegment = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? brandBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _segments[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.mutedText2,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                // Dynamic Appointments List via AsyncValueView
                AsyncValueView<List<Appointment>>(
                  value: appointmentsAsync,
                  loadingWidget: const CardSkeletonList(count: 2),
                  onRetry: () => ref.invalidate(appointmentsProvider),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EmptyState(
                          title: 'لا توجد مواعيد',
                          subtitle: 'لا توجد مواعيد مجدولة لهذا التحديد.',
                          icon: Icons.calendar_today_outlined,
                        ),
                      );
                    }
                    return Column(
                      children: items.map((appointment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildAppointmentCard(
                            context: context,
                            appointment: appointment,
                            onAccept: () => _onAccept(appointment),
                            onReject: () => _onReject(appointment),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required Appointment appointment,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    final statusText = switch (appointment.status) {
      AppointmentStatus.confirmed => 'تم التأكيد',
      AppointmentStatus.cancelled => 'ملغى',
      AppointmentStatus.completed => 'مكتمل',
      AppointmentStatus.pending => 'في الانتظار',
    };

    final statusColor = switch (appointment.status) {
      AppointmentStatus.confirmed => brandBlue,
      AppointmentStatus.cancelled => AppColors.errorRed,
      AppointmentStatus.completed => const Color(0xFF10B981),
      AppointmentStatus.pending => Colors.orange,
    };

    final timeRange =
        '${_formatTime(appointment.scheduledStart)} - ${_formatTime(appointment.scheduledEnd)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ProviderAppointmentDetailScreen(appointment: appointment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appointment.locationStatus,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink900,
                        ),
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
                          Text(
                            timeRange,
                            style: const TextStyle(
                              color: AppColors.mutedText2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceCard,
                    backgroundImage: appointment.patientAvatarUrl != null
                        ? NetworkImage(appointment.patientAvatarUrl!)
                        : null,
                    child: appointment.patientAvatarUrl == null
                        ? const Icon(Icons.person, color: AppColors.mutedText2)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniField(
                      'الرقم الطبي',
                      '#${appointment.medId}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniField(
                      'الحالة',
                      statusText,
                      statusColor: statusColor,
                    ),
                  ),
                ],
              ),
              if (appointment.status == AppointmentStatus.pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'قبول',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            foregroundColor: AppColors.ink900,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'رفض',
                            style: TextStyle(fontWeight: FontWeight.w700),
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

  static Widget _buildMiniField(
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: statusColor ?? AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
