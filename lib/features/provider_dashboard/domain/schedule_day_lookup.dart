import 'entities/doctor_schedule_template.dart';

/// Which of the doctor's weekly [DoctorScheduleTemplate] rows apply to
/// [date]'s ISO weekday (1 = Monday … 7 = Sunday — the same numbering as
/// Dart's `DateTime.weekday`, and the numbering
/// `GET /v1/doctors/me/schedule-templates` itself uses).
///
/// A doctor can have templates across several active affiliations/branches;
/// this returns every one of them that matches, across all of them — the
/// caller decides how to render "one clinic today" vs. "two clinics today".
/// An empty result means no template covers this weekday at any affiliation,
/// i.e. a day off.
///
/// Pure and stateless on purpose — this is not a provider, just a plain
/// function the home-screen agent can call directly with whatever
/// [templates] `myScheduleTemplatesProvider` already returned.
List<DoctorScheduleTemplate> scheduleTemplatesForDate(
  List<DoctorScheduleTemplate> templates,
  DateTime date,
) {
  final weekday = date.weekday;
  return templates.where((t) => t.weekday == weekday).toList();
}
