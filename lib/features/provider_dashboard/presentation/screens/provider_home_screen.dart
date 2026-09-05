import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/domain/schedule_day_lookup.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Currently selected day in the provider home calendar. Kept as a plain
/// `Notifier` (no codegen needed) — this is purely UI navigation state, not
/// server data.
class SelectedCalendarDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime date) => state = dateOnly(date);
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, DateTime>(
      SelectedCalendarDateNotifier.new,
    );

/// Provider home — for the selected date, shows which of the doctor's
/// clinic branches have working hours that day (per their real weekly
/// [DoctorScheduleTemplate]) and the real booked appointments at each,
/// rendered in that branch's own timezone. A day with no template at any
/// branch is a deliberate day off, not an error or missing-data state.
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  DateTime _weekStart(DateTime d) {
    var diff = d.weekday - DateTime.saturday;
    if (diff < 0) diff += 7;
    return dateOnly(d.subtract(Duration(days: diff)));
  }

  static const _dayAbbrev = {
    DateTime.saturday: 'سبت',
    DateTime.sunday: 'أحد',
    DateTime.monday: 'إثنين',
    DateTime.tuesday: 'ثلاثاء',
    DateTime.wednesday: 'أربعاء',
    DateTime.thursday: 'خميس',
    DateTime.friday: 'جمعة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final today = dateOnly(DateTime.now());
    final weekStart = _weekStart(selectedDate);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final templatesAsync = ref.watch(myScheduleTemplatesProvider());

    final unreadNotifsCount = ref
        .watch(doctorNotificationsProvider)
        .maybeWhen(data: (list) => list.where((n) => n.isUnread).length, orElse: () => 0);
    final avatarUrl = ref.watch(providerHeaderAvatarUrlProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(
            title: 'provider_dashboard.home.title'.tr(),
            unreadNotificationsCount: unreadNotifsCount,
            avatarUrl: avatarUrl,
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _MonthHeader(
                  selectedDate: selectedDate,
                  onPrevWeek: () => ref
                      .read(selectedCalendarDateProvider.notifier)
                      .select(selectedDate.subtract(const Duration(days: 7))),
                  onNextWeek: () => ref
                      .read(selectedCalendarDateProvider.notifier)
                      .select(selectedDate.add(const Duration(days: 7))),
                  onToday: dateOnly(selectedDate) == today
                      ? null
                      : () => ref.read(selectedCalendarDateProvider.notifier).select(today),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: weekDays.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = weekDays[index];
                      final dayTemplates = templatesAsync.maybeWhen(
                        data: (templates) => scheduleTemplatesForDate(templates, day),
                        orElse: () => const <DoctorScheduleTemplate>[],
                      );
                      return _DayTile(
                        key: Key('providerCalendarDayTile-$index'),
                        date: day,
                        isSelected: dateOnly(day) == dateOnly(selectedDate),
                        isToday: dateOnly(day) == today,
                        isWorkingDay: dayTemplates.isNotEmpty,
                        dayLabel: _dayAbbrev[day.weekday] ?? '',
                        onTap: () =>
                            ref.read(selectedCalendarDateProvider.notifier).select(day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: templatesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyState(
                        title: 'provider_dashboard.home.load_error'.tr(),
                        icon: Icons.error_outline,
                      ),
                    ),
                    data: (templates) {
                      final dayTemplates = scheduleTemplatesForDate(templates, selectedDate);
                      if (dayTemplates.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: EmptyState(
                            title: 'provider_dashboard.home.day_off_title'.tr(),
                            subtitle: 'provider_dashboard.home.day_off_subtitle'.tr(),
                            icon: Icons.weekend_outlined,
                          ),
                        );
                      }
                      return _WorkingDaysList(templates: dayTemplates, date: selectedDate);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.selectedDate,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'ar').format(selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _NavCircleButton(icon: Icons.chevron_left, onTap: onNextWeek),
          Expanded(
            child: Center(
              child: Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ),
          _NavCircleButton(icon: Icons.chevron_right, onTap: onPrevWeek),
          if (onToday != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'provider_dashboard.home.today'.tr(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: brandBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Icon(icon, size: 20, color: AppColors.mutedText2),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isWorkingDay,
    required this.dayLabel,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isWorkingDay;
  final String dayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: isSelected ? brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? brandBlue
                : (isToday ? brandBlue.withValues(alpha: 0.4) : const Color(0xFFF1F5F9)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.mutedText2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWorkingDay
                    ? (isSelected ? Colors.white : brandBlue)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One section per branch that has a working-hours template for the
/// selected date — each rendered independently so a doctor working two
/// branches the same weekday never sees an ambiguous merged window.
class _WorkingDaysList extends StatelessWidget {
  const _WorkingDaysList({required this.templates, required this.date});

  final List<DoctorScheduleTemplate> templates;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _BranchDaySection(
        template: templates[index],
        date: date,
      ),
    );
  }
}

class _BranchDaySection extends ConsumerWidget {
  const _BranchDaySection({required this.template, required this.date});

  final DoctorScheduleTemplate template;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStart = dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final appointmentsAsync = ref.watch(
      doctorAppointmentsProvider(
        from: dayStart,
        to: dayEnd,
        clinicBranchId: template.clinicBranchId,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
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
                      template.clinicName,
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
                        const Icon(Icons.access_time, size: 13, color: AppColors.mutedText2),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${template.startTime} - ${template.endTime} (${template.ianaTimezone})',
                            style: const TextStyle(color: AppColors.mutedText2, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              appointmentsAsync.maybeWhen(
                data: (page) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'provider_dashboard.home.booked_count'.tr(
                      args: [page.items.length.toString()],
                    ),
                    style: const TextStyle(
                      color: brandBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          appointmentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'provider_dashboard.home.load_error'.tr(),
                style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
              ),
            ),
            data: (page) {
              if (page.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'provider_dashboard.home.no_appointments'.tr(),
                    style: const TextStyle(color: AppColors.mutedText2, fontSize: 12.5),
                  ),
                );
              }
              final sorted = [...page.items]..sort((a, b) => a.startAt.compareTo(b.startAt));
              return Column(
                children: [
                  for (final appointment in sorted) ...[
                    ProviderAppointmentCard(
                      appointment: appointment,
                      onTap: () => _openDetail(context, appointment),
                    ),
                    if (appointment != sorted.last) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, DoctorAppointment appointment) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProviderAppointmentDetailScreen(
          appointmentId: appointment.appointmentId,
        ),
      ),
    );
  }
}
