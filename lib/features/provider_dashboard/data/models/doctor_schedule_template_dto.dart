import '../../domain/entities/doctor_schedule_template.dart';

/// Wire model for `/v1/doctors/me/schedule-templates` (File 12 Part 49.5).
class DoctorScheduleTemplateDto {
  const DoctorScheduleTemplateDto({
    required this.id,
    required this.doctorClinicAffiliationId,
    required this.clinicBranchId,
    required this.clinicId,
    required this.clinicName,
    required this.ianaTimezone,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.bufferMinutes,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorScheduleTemplateDto.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    return DoctorScheduleTemplateDto(
      id: json['id'] as String,
      doctorClinicAffiliationId:
          json['doctorClinicAffiliationId'] as String? ?? '',
      clinicBranchId: json['clinicBranchId'] as String? ?? '',
      clinicId: json['clinicId'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      ianaTimezone: json['ianaTimezone'] as String? ?? 'UTC',
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '17:00',
      slotDurationMinutes: (json['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      bufferMinutes: (json['bufferMinutes'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? now),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? now),
    );
  }

  final String id;
  final String doctorClinicAffiliationId;
  final String clinicBranchId;
  final String clinicId;
  final String clinicName;
  final String ianaTimezone;
  final int weekday;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final int bufferMinutes;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorScheduleTemplate toEntity() => DoctorScheduleTemplate(
    id: id,
    doctorClinicAffiliationId: doctorClinicAffiliationId,
    clinicBranchId: clinicBranchId,
    clinicId: clinicId,
    clinicName: clinicName,
    ianaTimezone: ianaTimezone,
    weekday: weekday,
    startTime: startTime,
    endTime: endTime,
    slotDurationMinutes: slotDurationMinutes,
    bufferMinutes: bufferMinutes,
    version: version,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static Map<String, dynamic> createBody(NewDoctorScheduleTemplate template) => {
    'doctorClinicAffiliationId': template.doctorClinicAffiliationId,
    'weekday': template.weekday,
    'startTime': template.startTime,
    'endTime': template.endTime,
    'slotDurationMinutes': template.slotDurationMinutes,
    'bufferMinutes': template.bufferMinutes,
  };

  /// `version` is sent as a normal body field on PATCH — the backend reads it
  /// as the optimistic-lock token and 409s on a mismatch (File 12 Part 49.6).
  static Map<String, dynamic> patchBody(DoctorScheduleTemplatePatch patch) => {
    if (patch.weekday != null) 'weekday': patch.weekday,
    if (patch.startTime != null) 'startTime': patch.startTime,
    if (patch.endTime != null) 'endTime': patch.endTime,
    if (patch.slotDurationMinutes != null)
      'slotDurationMinutes': patch.slotDurationMinutes,
    if (patch.bufferMinutes != null) 'bufferMinutes': patch.bufferMinutes,
    if (patch.version != null) 'version': patch.version,
  };
}
