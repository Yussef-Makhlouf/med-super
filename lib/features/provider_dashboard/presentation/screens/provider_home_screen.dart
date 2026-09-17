import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/domain/schedule_day_lookup.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/branch_tab.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';

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

/// Provider home — for the selected date, shows a per-branch hourly timeline
/// merging the doctor's real `OPEN` slots (bookable directly from here) with
/// their real booked appointments, one tab per branch the doctor is
/// affiliated with (plus an "all branches" tab when there is more than one),
/// mirroring the original mock-data calendar this screen shipped with before
/// the real appointments/slots endpoints existed.
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  /// Wraps a non-scrolling empty/error state in a scrollable so
  /// `RefreshIndicator` can still detect the pull gesture and its own
  /// `EmptyState`/error content stays centered as before.
  Widget _refreshableEmpty(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

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
    final clinicsAsync = ref.watch(myClinicsProvider);
    final doctorId = ref
        .watch(doctorAccountProvider)
        .maybeWhen(data: (account) => account.id, orElse: () => null);

    final unreadNotifsCount = ref.watch(unreadNotificationCountProvider);
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
                  child: Builder(
                    builder: (context) {
                      Future<void> onRefresh() async {
                        ref.invalidate(myClinicsProvider);
                        ref.invalidate(myScheduleTemplatesProvider());
                        ref.invalidate(doctorAccountProvider);
                        if (doctorId != null) {
                          final dayStart = dateOnly(selectedDate);
                          final dayEnd = dayStart.add(const Duration(days: 1));
                          for (final branch in clinicsAsync.value ?? const <DoctorClinic>[]) {
                            ref.invalidate(
                              doctorOpenSlotsProvider((
                                doctorId: doctorId,
                                clinicBranchId: branch.clinicBranchId,
                                from: dayStart,
                                to: dayEnd,
                              )),
                            );
                          }
                          ref.invalidate(doctorAppointmentsProvider);
                        }
                        // Give the invalidated providers a moment to refetch
                        // so the spinner doesn't vanish before new data lands.
                        await Future<void>.delayed(const Duration(milliseconds: 400));
                      }

                      return clinicsAsync.when(
                        loading: () => const CardSkeletonList(count: 3),
                        error: (error, _) => RefreshIndicator(
                          onRefresh: onRefresh,
                          child: _refreshableEmpty(
                            EmptyState(
                              title: 'provider_dashboard.home.load_error'.tr(),
                              icon: Icons.error_outline,
                            ),
                          ),
                        ),
                        data: (clinics) {
                          final branches = clinics
                              .where((c) => c.isAcceptingBookings)
                              .toList();
                          if (branches.isEmpty || doctorId == null) {
                            return RefreshIndicator(
                              onRefresh: onRefresh,
                              child: _refreshableEmpty(
                                EmptyState(
                                  title: 'provider_dashboard.home.day_off_title'.tr(),
                                  subtitle: 'provider_dashboard.home.day_off_subtitle'.tr(),
                                  icon: Icons.weekend_outlined,
                                ),
                              ),
                            );
                          }
                          return _BranchTimelineTabs(
                            branches: branches,
                            date: selectedDate,
                            doctorId: doctorId,
                            onRefresh: onRefresh,
                          );
                        },
                      );
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

/// One tab per branch the doctor is affiliated with, plus a combined "all
/// branches" tab when there is more than one — each tab shows the same
/// hour-by-hour timeline, scoped to that branch (or every branch at once).
class _BranchTimelineTabs extends StatefulWidget {
  const _BranchTimelineTabs({
    required this.branches,
    required this.date,
    required this.doctorId,
    required this.onRefresh,
  });

  final List<DoctorClinic> branches;
  final DateTime date;
  final String doctorId;
  final Future<void> Function() onRefresh;

  @override
  State<_BranchTimelineTabs> createState() => _BranchTimelineTabsState();
}

class _BranchTimelineTabsState extends State<_BranchTimelineTabs>
    with TickerProviderStateMixin {
  late TabController _controller;

  bool get _showAllTab => widget.branches.length > 1;
  int get _tabCount => widget.branches.length + (_showAllTab ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabCount, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _BranchTimelineTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branches.length != widget.branches.length) {
      final previousIndex = _controller.index;
      _controller.dispose();
      _controller = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: previousIndex < _tabCount ? previousIndex : 0,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branches.length == 1) {
      return _BranchDayTimeline(
        branch: widget.branches.first,
        date: widget.date,
        doctorId: widget.doctorId,
        onRefresh: widget.onRefresh,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: brandBlue,
            unselectedLabelColor: AppColors.mutedText2,
            indicatorColor: brandBlue,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              if (_showAllTab) Tab(text: 'provider_dashboard.home.tab_all'.tr()),
              for (final branch in widget.branches) BranchTab(branch: branch),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              if (_showAllTab)
                _AllBranchesTimeline(
                  branches: widget.branches,
                  date: widget.date,
                  doctorId: widget.doctorId,
                  onRefresh: widget.onRefresh,
                ),
              for (final branch in widget.branches)
                _BranchDayTimeline(
                  branch: branch,
                  date: widget.date,
                  doctorId: widget.doctorId,
                  onRefresh: widget.onRefresh,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tab labelled the same way a branch is identified in the doctor's own
/// "my clinics" list (`_ClinicBranchListTile`): the branch's city as the
/// bold title, with the street address alone as a muted subtitle
/// underneath.
/// All branches' rows merged into one time-sorted list, each row labelled
/// with its branch name so it's unambiguous which clinic a slot belongs to.
class _AllBranchesTimeline extends ConsumerWidget {
  const _AllBranchesTimeline({
    required this.branches,
    required this.date,
    required this.doctorId,
    required this.onRefresh,
  });

  final List<DoctorClinic> branches;
  final DateTime date;
  final String doctorId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsByBranch = <DoctorClinic, AsyncValue<List<_TimelineRow>>>{
      for (final branch in branches)
        branch: _watchTimelineRows(ref, doctorId: doctorId, branch: branch, date: date),
    };

    if (rowsByBranch.values.any((v) => v.isLoading)) {
      return const CardSkeletonList(count: 3);
    }
    final firstError = rowsByBranch.values.firstWhere(
      (v) => v.hasError,
      orElse: () => const AsyncValue.data([]),
    );
    if (firstError.hasError) {
      // RefreshIndicator here too — a doctor whose day starts with a load
      // error still expects pull-to-refresh to work, same as every other
      // state in this timeline.
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: _scrollableCenter(
          ErrorBanner(
            message: providerFailureMessageOf(firstError.error!),
            onRetry: () {
              for (final branch in branches) {
                ref.invalidate(
                  doctorOpenSlotsProvider((
                    doctorId: doctorId,
                    clinicBranchId: branch.clinicBranchId,
                    from: dateOnly(date),
                    to: dateOnly(date).add(const Duration(days: 1)),
                  )),
                );
              }
            },
          ),
        ),
      );
    }

    final all = <MapEntry<DoctorClinic, _TimelineRow>>[
      for (final entry in rowsByBranch.entries)
        for (final row in entry.value.value!) MapEntry(entry.key, row),
    ]..sort((a, b) => a.value.startAt.compareTo(b.value.startAt));

    if (all.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: _scrollableCenter(
          EmptyState(
            title: 'provider_dashboard.home.day_off_title'.tr(),
            subtitle: 'provider_dashboard.home.day_off_subtitle'.tr(),
            icon: Icons.weekend_outlined,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
      // Without this, a short list (fewer rows than fit the viewport)
      // never overscrolls, so the RefreshIndicator wrapping this screen
      // never sees the pull gesture and pull-to-refresh silently does
      // nothing on days with few appointments.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: all.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _TimelineRowTile(
        row: all[index].value,
        branch: all[index].key,
        doctorId: doctorId,
        showBranchLabel: true,
      ),
      ),
    );
  }

  /// Wraps non-list content (error/empty states) in a scrollable so
  /// `RefreshIndicator` can detect the pull gesture on those states too.
  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchDayTimeline extends ConsumerWidget {
  const _BranchDayTimeline({
    required this.branch,
    required this.date,
    required this.doctorId,
    required this.onRefresh,
  });

  final DoctorClinic branch;
  final DateTime date;
  final String doctorId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = _watchTimelineRows(ref, doctorId: doctorId, branch: branch, date: date);

    return rowsAsync.when(
      loading: () => const CardSkeletonList(count: 3),
      error: (error, _) => RefreshIndicator(
        onRefresh: onRefresh,
        child: _scrollableCenter(
          ErrorBanner(
            message: providerFailureMessageOf(error),
            onRetry: () => ref.invalidate(
              doctorOpenSlotsProvider((
                doctorId: doctorId,
                clinicBranchId: branch.clinicBranchId,
                from: dateOnly(date),
                to: dateOnly(date).add(const Duration(days: 1)),
              )),
            ),
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: _scrollableCenter(
              EmptyState(
                title: 'provider_dashboard.home.day_off_title'.tr(),
                subtitle: 'provider_dashboard.home.day_off_subtitle'.tr(),
                icon: Icons.weekend_outlined,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            // See the same fix in _AllBranchesTimeline above for why this is
            // required for RefreshIndicator to work on a short list.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _TimelineRowTile(
              row: rows[index],
              branch: branch,
              doctorId: doctorId,
              showBranchLabel: false,
            ),
          ),
        );
      },
    );
  }

  /// Wraps non-list content (error/empty states) in a scrollable so
  /// `RefreshIndicator` can detect the pull gesture on those states too.
  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// One row on the day timeline: either a real booked [appointment], or an
/// open bookable [slot] — exactly one of the two is set.
class _TimelineRow {
  _TimelineRow.booked(DoctorAppointment appointment)
    : appointment = appointment,
      slot = null,
      startAt = appointment.startAt,
      endAt = appointment.endAt;

  _TimelineRow.open(DoctorSlot slot)
    : appointment = null,
      slot = slot,
      startAt = slot.startAtUtc,
      endAt = slot.endAtUtc;

  final DoctorAppointment? appointment;
  final DoctorSlot? slot;
  final DateTime startAt;
  final DateTime endAt;

  bool get isBooked => appointment != null;
}

/// Merges a branch's real booked appointments for [date] with its real open
/// slots into one time-sorted list of [_TimelineRow]s.
AsyncValue<List<_TimelineRow>> _watchTimelineRows(
  WidgetRef ref, {
  required String doctorId,
  required DoctorClinic branch,
  required DateTime date,
}) {
  final dayStart = dateOnly(date);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final appointmentsAsync = ref.watch(
    doctorAppointmentsProvider(
      from: dayStart,
      to: dayEnd,
      clinicBranchId: branch.clinicBranchId,
    ),
  );
  final openSlotsAsync = ref.watch(
    doctorOpenSlotsProvider((
      doctorId: doctorId,
      clinicBranchId: branch.clinicBranchId,
      from: dayStart,
      to: dayEnd,
    )),
  );

  if (appointmentsAsync.isLoading || openSlotsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (appointmentsAsync.hasError) {
    return AsyncValue.error(appointmentsAsync.error!, appointmentsAsync.stackTrace!);
  }
  if (openSlotsAsync.hasError) {
    return AsyncValue.error(openSlotsAsync.error!, openSlotsAsync.stackTrace!);
  }

  final appointments = appointmentsAsync.value!.items;
  final openSlots = openSlotsAsync.value!.where(
    (s) => dateOnly(s.startAtUtc.toLocal()) == dayStart,
  );

  final rows = <_TimelineRow>[
    for (final appointment in appointments) _TimelineRow.booked(appointment),
    for (final slot in openSlots) _TimelineRow.open(slot),
  ]..sort((a, b) => a.startAt.compareTo(b.startAt));

  return AsyncValue.data(rows);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
  return (parts.first.characters.take(1).toString() + parts.last.characters.take(1).toString())
      .toUpperCase();
}

class _TimelineRowTile extends ConsumerWidget {
  const _TimelineRowTile({
    required this.row,
    required this.branch,
    required this.doctorId,
    required this.showBranchLabel,
  });

  final _TimelineRow row;
  final DoctorClinic branch;
  final String doctorId;
  final bool showBranchLabel;

  bool get _isPast => row.endAt.isBefore(DateTime.now().toUtc());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLabel = formatAppointmentTime(row.startAt);
    final durationMinutes = row.endAt.difference(row.startAt).inMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink900),
                ),
                Text(
                  '$durationMinutes ${'provider_dashboard.home.minutes_short'.tr()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: row.isBooked
                ? _bookedContent(context)
                : _openContent(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _bookedContent(BuildContext context) {
    final appointment = row.appointment!;
    final lifecycleStatus = doctorAppointmentStatusStyle(appointment.status);
    return InkWell(
      onTap: () => showProviderAppointmentDetailSheet(
        context,
        appointmentId: appointment.appointmentId,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: brandBlue.withValues(alpha: 0.12),
            child: Text(
              _initials(appointment.patientName),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: brandBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink900),
                ),
                if (showBranchLabel)
                  Text(
                    '${branch.address.city} · ${branch.address.line1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (appointment.status == DoctorAppointmentStatus.confirmed)
            DoctorVisitStatusBadge(status: appointment.visitStatus)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: lifecycleStatus.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lifecycleStatus.label,
                style: TextStyle(
                  color: lifecycleStatus.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _openContent(BuildContext context, WidgetRef ref) {
    final slot = row.slot!;
    final isPast = _isPast;
    return InkWell(
      onTap: isPast ? null : () => _bookSlot(context, ref, slot),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.history_toggle_off : Icons.add_circle_outline,
            size: 20,
            color: isPast ? AppColors.mutedText2 : brandBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPast
                      ? 'provider_dashboard.home.slot_past'.tr()
                      : 'provider_dashboard.home.slot_open'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isPast ? AppColors.mutedText2 : brandBlue,
                  ),
                ),
                if (showBranchLabel)
                  Text(
                    '${branch.address.city} · ${branch.address.line1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookSlot(BuildContext context, WidgetRef ref, DoctorSlot slot) async {
    final booked = await showModalBottomSheet<(DoctorClinic, DoctorSlot)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _QuickBookSheet(
          doctorId: doctorId,
          initialBranch: branch,
          slot: slot,
        ),
      ),
    );
    if (booked != null) {
      // The sheet lets the doctor switch branches, so the slot actually
      // booked may belong to a different branch than the one tapped —
      // invalidate by that branch, not the outer `branch`.
      final (bookedBranch, bookedSlot) = booked;
      final dayStart = dateOnly(bookedSlot.startAtUtc.toLocal());
      ref.invalidate(
        doctorOpenSlotsProvider((
          doctorId: doctorId,
          clinicBranchId: bookedBranch.clinicBranchId,
          from: dayStart,
          to: dayStart.add(const Duration(days: 1)),
        )),
      );
      ref.invalidate(doctorAppointmentsProvider);
    }
  }
}

/// A patient-phone/name form for booking directly from the timeline's "+"
/// button. Pre-selects the branch/slot the user tapped (same as the full
/// [showBookWalkInAppointmentSheet] flow's first two steps), but still lets
/// the doctor switch branches here instead of forcing them to cancel and
/// reopen the full flow just to pick a different one.
class _QuickBookSheet extends ConsumerStatefulWidget {
  const _QuickBookSheet({
    required this.doctorId,
    required this.initialBranch,
    required this.slot,
  });

  final String doctorId;
  final DoctorClinic initialBranch;
  final DoctorSlot slot;

  @override
  ConsumerState<_QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends ConsumerState<_QuickBookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  late DoctorClinic _branch;
  DoctorSlot? _slot;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branch = widget.initialBranch;
    _slot = widget.slot;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _switchBranch(DoctorClinic branch) {
    if (branch.clinicBranchId == _branch.clinicBranchId) return;
    setState(() {
      _branch = branch;
      // The originally tapped slot belongs to the old branch — a new one
      // must be picked before submitting is possible again.
      _slot = null;
    });
  }

  Future<void> _submit() async {
    final slot = _slot;
    if (slot == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final phone = normalizeEgyptPhone(_phoneController.text.trim());
    final name = _nameController.text.trim();

    final result = await ref
        .read(bookWalkInAppointmentUseCaseProvider)
        .call(
          clinicBranchId: _branch.clinicBranchId,
          slotId: slot.slotId,
          patientPhone: phone,
          patientName: name,
        );

    if (!mounted) return;
    result.when(
      ok: (_) => Navigator.of(context).pop((_branch, slot)),
      err: (failure) => setState(() {
        _submitting = false;
        _error = providerFailureMessage(failure);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'provider_dashboard.walk_in.step_patient'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.left,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'provider_dashboard.walk_in.phone_label'.tr(),
                  hintText: 'provider_dashboard.walk_in.phone_hint'.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) return 'provider_dashboard.walk_in.phone_required'.tr();
                  if (!isValidEgyptPhone(trimmed)) return 'provider_dashboard.walk_in.phone_invalid'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'provider_dashboard.walk_in.name_label'.tr(),
                  hintText: 'provider_dashboard.walk_in.name_hint'.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'provider_dashboard.walk_in.name_required'.tr() : null,
              ),
              const SizedBox(height: 20),
              Text(
                'provider_dashboard.walk_in.step_branch'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              ref
                  .watch(myClinicsProvider)
                  .when(
                    loading: () => SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, _) => const SkeletonLoader(
                          width: 130,
                          height: 72,
                          borderRadius: 12,
                        ),
                      ),
                    ),
                    error: (error, _) => ErrorBanner(
                      message: providerFailureMessageOf(error),
                      onRetry: () => ref.invalidate(myClinicsProvider),
                    ),
                    data: (clinics) {
                      final acceptingBranches = clinics
                          .where((c) => c.isAcceptingBookings)
                          .toList();
                      return SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: acceptingBranches.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) =>
                              _branchChip(acceptingBranches[index]),
                        ),
                      );
                    },
                  ),
              if (_slot == null) ...[
                const SizedBox(height: 20),
                Text(
                  'provider_dashboard.walk_in.step_slot'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 8),
                _slotPicker(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_slot != null && !_submitting) ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('provider_dashboard.walk_in.submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _branchChip(DoctorClinic clinic) {
    final selected = _branch.clinicBranchId == clinic.clinicBranchId;
    return GestureDetector(
      onTap: () => _switchBranch(clinic),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? brandBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? brandBlue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  size: 14,
                  color: selected ? brandBlue : AppColors.mutedText2,
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle, color: brandBlue, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              clinic.address.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              clinic.displayAddressLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedText2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotPicker() {
    final async = ref.watch(
      doctorOpenSlotsProvider((
        doctorId: widget.doctorId,
        clinicBranchId: _branch.clinicBranchId,
        from: null,
        to: null,
      )),
    );

    return async.when(
      loading: () => SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, _) =>
              const SkeletonLoader(width: 62, height: 64, borderRadius: 14),
        ),
      ),
      error: (error, _) => ErrorBanner(
        message: providerFailureMessageOf(error),
        onRetry: () => ref.invalidate(
          doctorOpenSlotsProvider((
            doctorId: widget.doctorId,
            clinicBranchId: _branch.clinicBranchId,
            from: null,
            to: null,
          )),
        ),
      ),
      data: (slots) {
        if (slots.isEmpty) {
          return EmptyState(
            title: 'provider_dashboard.walk_in.no_slots'.tr(),
            icon: Icons.event_busy_outlined,
          );
        }
        final sorted = [...slots]
          ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final slot in sorted) _slotChip(slot)],
        );
      },
    );
  }

  Widget _slotChip(DoctorSlot slot) {
    final selected = _slot?.slotId == slot.slotId;
    return GestureDetector(
      onTap: () => setState(() => _slot = slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? brandBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? brandBlue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          formatAppointmentTime(slot.startAtUtc),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: selected ? brandBlue : AppColors.ink900,
          ),
        ),
      ),
    );
  }
}
