/// A recurring weekly availability window
/// (`GET /v1/doctors/me/schedule-templates`, File 12 Part 49.5).
///
/// This replaces the mock-only `{working_days: [{day, is_enabled, from, to}]}`
/// blob. Three things the old shape could not express and the real one
/// requires:
///
///  * a template belongs to **one affiliation** — a doctor at two branches
///    keeps two independent weekly plans, not one shared one;
///  * `slotDurationMinutes`/`bufferMinutes` decide how the window is cut into
///    bookable slots, and had no mock equivalent at all;
///  * times are `"HH:mm"` **local to the branch's [ianaTimezone]**, not the
///    device's — which is why the zone travels with every row.
///
/// Editing or deleting a template affects **future slot generation only**.
/// Already-generated slots, including ones patients hold or have booked, are
/// never touched (File 12 Part 33.8 / File 11 05.3).
class DoctorScheduleTemplate {
  const DoctorScheduleTemplate({
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

  final String id;
  final String doctorClinicAffiliationId;
  final String clinicBranchId;
  final String clinicId;
  final String clinicName;
  final String ianaTimezone;

  /// ISO-8601 weekday: 1 = Monday … 7 = Sunday (File 12 Part 33.5).
  /// Note this is the same numbering as Dart's `DateTime.weekday`.
  final int weekday;

  /// `"HH:mm"`, 24-hour, local to [ianaTimezone].
  final String startTime;
  final String endTime;

  final int slotDurationMinutes;
  final int bufferMinutes;

  /// Optimistic-lock token. Send it back on update/delete to get a
  /// `409 OPTIMISTIC_LOCK_CONFLICT` instead of silently overwriting a
  /// concurrent edit (File 12 Part 49.6).
  final int version;

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// A pending create — no id or version yet.
class NewDoctorScheduleTemplate {
  const NewDoctorScheduleTemplate({
    required this.doctorClinicAffiliationId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    this.bufferMinutes = 0,
  });

  final String doctorClinicAffiliationId;
  final int weekday;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final int bufferMinutes;
}

/// A partial update. Every field is optional; `version` carries the
/// optimistic-lock token from the row this edit was based on.
class DoctorScheduleTemplatePatch {
  const DoctorScheduleTemplatePatch({
    this.weekday,
    this.startTime,
    this.endTime,
    this.slotDurationMinutes,
    this.bufferMinutes,
    this.version,
  });

  final int? weekday;
  final String? startTime;
  final String? endTime;
  final int? slotDurationMinutes;
  final int? bufferMinutes;
  final int? version;
}
