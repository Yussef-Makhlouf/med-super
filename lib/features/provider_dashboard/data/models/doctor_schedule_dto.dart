import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';

class DoctorScheduleDto {
  const DoctorScheduleDto({required this.workingDays});

  factory DoctorScheduleDto.fromJson(Map<String, dynamic> json) {
    final list = (json['working_days'] as List<dynamic>?) ?? [];
    final days = list.map((item) {
      final map = item as Map<String, dynamic>;
      final dayStr = map['day'] as String;
      final day = Weekday.values.firstWhere(
        (w) => w.name == dayStr,
        orElse: () => Weekday.saturday,
      );
      final isEnabled = map['is_enabled'] as bool? ?? false;

      ClinicTime? parseTime(Map<String, dynamic>? timeMap) {
        if (timeMap == null) return null;
        return ClinicTime(
          hour: timeMap['hour'] as int? ?? 9,
          minute: timeMap['minute'] as int? ?? 0,
        );
      }

      return ClinicWorkingDay(
        day: day,
        isEnabled: isEnabled,
        from: parseTime(map['from'] as Map<String, dynamic>?),
        to: parseTime(map['to'] as Map<String, dynamic>?),
      );
    }).toList();

    return DoctorScheduleDto(workingDays: days);
  }

  final List<ClinicWorkingDay> workingDays;

  Map<String, dynamic> toJson() {
    return {
      'working_days': workingDays.map((d) {
        return {
          'day': d.day.name,
          'is_enabled': d.isEnabled,
          'from': d.from != null
              ? {'hour': d.from!.hour, 'minute': d.from!.minute}
              : null,
          'to': d.to != null
              ? {'hour': d.to!.hour, 'minute': d.to!.minute}
              : null,
        };
      }).toList(),
    };
  }
}
