import '../entities/available_day.dart';
import '../entities/doctor_slot.dart';
import '../entities/time_slot.dart';

/// Egypt-first MVP simplification: fixed +02:00 offset for `Africa/Cairo`
/// (matching the backend's `PROVIDER_REGISTRATION_CONSTANTS.DEFAULT_IANA_TIMEZONE`
/// default). Egypt has observed no DST since 2014, so a fixed offset is
/// accurate for this single-market MVP. This is deliberately NOT a general
/// IANA converter — no timezone/tzdata package is in pubspec.yaml. Any other
/// `ianaTimezone` value is treated as unknown and shown as UTC rather than
/// silently mislabeled as correct local time (see
/// med-super/docs/backend_frontend_parity_matrix.md).
const Map<String, Duration> _knownFixedOffsets = {
  'Africa/Cairo': Duration(hours: 2),
};

/// ISO weekday 1..7 (Monday..Sunday), matching FILE_12 Part 33.5's convention.
const List<String> _arabicWeekdays = [
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

class _Localized {
  const _Localized(this.time, this.isKnownZone);
  final DateTime time;
  final bool isKnownZone;
}

_Localized _toLocal(DateTime utc, String? ianaTimezone) {
  final offset = ianaTimezone == null
      ? null
      : _knownFixedOffsets[ianaTimezone];
  if (offset == null) {
    return _Localized(utc, false);
  }
  return _Localized(utc.add(offset), true);
}

String _timeLabel(_Localized localized) {
  final hour24 = localized.time.hour;
  final isPm = hour24 >= 12;
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  final hh = hour12.toString().padLeft(2, '0');
  final mm = localized.time.minute.toString().padLeft(2, '0');
  final suffix = isPm ? 'م' : 'ص';
  final label = '$hh:$mm $suffix';
  return localized.isKnownZone ? label : '$label UTC';
}

String _dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

String _dayLabel(DateTime local, DateTime today) {
  final localDay = DateTime(local.year, local.month, local.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final diff = localDay.difference(todayDay).inDays;
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'غداً';
  return _arabicWeekdays[local.weekday - 1];
}

/// Groups real backend slots (`DoctorSlot`, UTC) into the `AvailableDay`/
/// `TimeSlot` shape the existing doctor-detail UI (`_SlotsCard`) already
/// renders — swaps the data source from static mock data to a real Phase 3
/// API call without requiring any change to the widget tree. Every slot the
/// backend returns from this endpoint is already `OPEN`, so `available` is
/// always `true` here — there is no hold/booking state to reflect (Phase 4
/// doesn't exist yet).
List<AvailableDay> groupSlotsIntoAvailableDays(
  List<DoctorSlot> slots, {
  String? ianaTimezone,
  DateTime? nowUtc,
}) {
  final now = _toLocal(nowUtc ?? DateTime.now().toUtc(), ianaTimezone).time;
  final byDay = <String, List<DoctorSlot>>{};
  for (final slot in slots) {
    final local = _toLocal(slot.startAtUtc, ianaTimezone).time;
    byDay.putIfAbsent(_dayKey(local), () => <DoctorSlot>[]).add(slot);
  }

  final dayKeys = byDay.keys.toList()..sort();
  return dayKeys.map((key) {
    final daySlots = byDay[key]!
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final firstLocal = _toLocal(daySlots.first.startAtUtc, ianaTimezone).time;
    return AvailableDay(
      id: key,
      label: _dayLabel(firstLocal, now),
      dayNumber: firstLocal.day,
      slots: daySlots
          .map(
            (s) => TimeSlot(
              id: s.slotId,
              label: _timeLabel(_toLocal(s.startAtUtc, ianaTimezone)),
              available: true,
            ),
          )
          .toList(),
    );
  }).toList();
}
