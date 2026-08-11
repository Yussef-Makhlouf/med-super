enum Weekday { saturday, sunday, monday, tuesday, wednesday, thursday, friday }

/// Domain-pure time-of-day value (no Flutter/`TimeOfDay` dependency here).
class ClinicTime {
  const ClinicTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}

class ClinicWorkingDay {
  const ClinicWorkingDay({
    required this.day,
    required this.isEnabled,
    this.from,
    this.to,
  });

  final Weekday day;
  final bool isEnabled;
  final ClinicTime? from;
  final ClinicTime? to;

  ClinicWorkingDay copyWith({
    bool? isEnabled,
    ClinicTime? from,
    ClinicTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) => ClinicWorkingDay(
    day: day,
    isEnabled: isEnabled ?? this.isEnabled,
    from: clearFrom ? null : (from ?? this.from),
    to: clearTo ? null : (to ?? this.to),
  );
}
