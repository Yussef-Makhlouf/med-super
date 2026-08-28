import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/schedule_slot.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_calendar_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/book_slot_bottom_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/slot_detail_bottom_sheet.dart';

/// Provider home — a calendar of the day's schedule, showing open and
/// booked slots. Mock data only for now; no backend contract exists yet
/// for per-date bookable slots (see provider_calendar_providers.dart).
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
    final slots = ref.watch(scheduleSlotsForDateProvider(selectedDate));
    final bookedCount = slots.where((s) => s.status == ScheduleSlotStatus.booked).length;
    final unreadNotifsCount = ref
        .watch(doctorNotificationsProvider)
        .maybeWhen(data: (list) => list.where((n) => n.isUnread).length, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          ProviderPageHeader(title: 'الجدول', unreadNotificationsCount: unreadNotifsCount),
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
                      return _DayTile(
                        key: Key('providerCalendarDayTile-$index'),
                        date: day,
                        isSelected: dateOnly(day) == dateOnly(selectedDate),
                        isToday: dateOnly(day) == today,
                        dayLabel: _dayAbbrev[day.weekday] ?? '',
                        onTap: () =>
                            ref.read(selectedCalendarDateProvider.notifier).select(day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _Legend(bookedCount: bookedCount, totalCount: slots.length),
                const SizedBox(height: 8),
                Expanded(
                  child: slots.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: EmptyState(
                            title: 'يوم إجازة',
                            subtitle: 'لا توجد مواعيد متاحة يوم الجمعة.',
                            icon: Icons.weekend_outlined,
                          ),
                        )
                      : _DayTimeline(slots: slots, date: selectedDate),
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
                child: const Text(
                  'اليوم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: brandBlue),
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
    required this.dayLabel,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final String dayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final daySlots = ref.watch(scheduleSlotsForDateProvider(date));
        final hasBookings = daySlots.any((s) => s.status == ScheduleSlotStatus.booked);
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
                    color: hasBookings
                        ? (isSelected ? Colors.white : brandBlue)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.bookedCount, required this.totalCount});

  final int bookedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _LegendDot(color: brandBlue.withValues(alpha: 0.5), label: 'متاح'),
          const SizedBox(width: 14),
          _LegendDot(color: brandBlue, label: 'محجوز'),
          const Spacer(),
          if (totalCount > 0)
            Text(
              '$bookedCount من $totalCount محجوز',
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText2)),
      ],
    );
  }
}

/// Google Calendar-style day view — an hour-gridded axis with slot blocks
/// positioned/sized by their actual time and duration, instead of a plain
/// uniform list.
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.slots, required this.date});

  final List<ScheduleSlot> slots;
  final DateTime date;

  static const _startHour = 9;
  static const _endHour = 17;
  static const _hourHeight = 96.0;
  static const _gutter = 46.0;

  double _offsetFor(DateTime t) =>
      (t.hour - _startHour) * _hourHeight + (t.minute / 60) * _hourHeight;

  String _hourLabel(int h) {
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = (_endHour - _startHour) * _hourHeight;
    final now = DateTime.now();
    final isToday = dateOnly(date) == dateOnly(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            for (var h = _startHour; h <= _endHour; h++)
              Positioned(
                top: (h - _startHour) * _hourHeight,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    SizedBox(
                      width: _gutter,
                      child: Text(
                        _hourLabel(h),
                        style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText2),
                      ),
                    ),
                    const Expanded(child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  ],
                ),
              ),
            if (isToday && now.hour >= _startHour && now.hour < _endHour)
              Positioned(
                top: _offsetFor(now),
                left: _gutter + 6,
                right: 0,
                child: Container(height: 2, color: AppColors.errorRed),
              ),
            for (final slot in slots)
              Positioned(
                top: _offsetFor(slot.start) + 2,
                left: _gutter + 6,
                right: 0,
                height:
                    _hourHeight * (slot.end.difference(slot.start).inMinutes / 60) - 4,
                child: _SlotBlock(slot: slot),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotBlock extends ConsumerWidget {
  const _SlotBlock({required this.slot});

  final ScheduleSlot slot;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'.toUpperCase();
  }

  void _openBookSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookSlotBottomSheet(
        slot: slot,
        onConfirm: (patientName, note) => ref
            .read(scheduleOverridesProvider.notifier)
            .book(slot, patientName: patientName, note: note),
      ),
    );
  }

  void _openDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SlotDetailBottomSheet(
        slot: slot,
        onCancel: () => ref.read(scheduleOverridesProvider.notifier).cancel(slot),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBooked = slot.status == ScheduleSlotStatus.booked;
    // A past, never-booked slot can't be booked retroactively — the visit
    // window is already gone. Booked past slots stay tappable (read-only
    // detail view), just without the cancel action — see SlotDetailBottomSheet.
    final isPastUnbooked = !isBooked && slot.start.isBefore(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPastUnbooked
            ? null
            : () => isBooked ? _openDetailSheet(context, ref) : _openBookSheet(context, ref),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPastUnbooked
                ? AppColors.surfaceCard
                : (isBooked ? Colors.white : brandBlue.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPastUnbooked
                  ? const Color(0xFFF1F5F9)
                  : (isBooked ? const Color(0xFFF1F5F9) : brandBlue.withValues(alpha: 0.25)),
            ),
          ),
          child: isBooked
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: brandBlue.withValues(alpha: 0.12),
                      child: Text(
                        _initials(slot.patientName ?? '?'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.patientName ?? '',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      isPastUnbooked ? Icons.history_toggle_off : Icons.add_circle_outline,
                      size: 14,
                      color: isPastUnbooked
                          ? AppColors.mutedText
                          : brandBlue.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isPastUnbooked ? 'انتهى الوقت' : 'متاح',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isPastUnbooked
                              ? AppColors.mutedText
                              : brandBlue.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
