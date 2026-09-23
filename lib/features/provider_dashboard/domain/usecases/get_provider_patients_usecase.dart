import 'package:med_super/core/error/result.dart';
import '../entities/doctor_appointment.dart';
import '../entities/patient.dart';
import '../repositories/provider_dashboard_repository.dart';

/// Derives the doctor's patient list purely from `GET
/// /v1/doctors/me/appointments` — there is no dedicated patients endpoint.
///
/// Pages through the real cursor-paginated list (walking `nextCursor` until
/// `null`) over a **±90-day window around today**, mirroring the exact bound
/// `ProviderPatientDetailScreen` already uses for its own appointment-history
/// fallback (that screen filters client-side within the same window since
/// the appointments endpoint has no `patientId` filter either). Results are
/// deduplicated by `patientId`, keeping the most recent appointment's
/// name/phone (appointments are returned in ascending `startAt` order per
/// the backend's list use-case, so the last one seen for a patient is the
/// most recent) plus that patient's earliest/latest appointment `startAt`
/// across the whole window.
class GetProviderPatientsUseCase {
  const GetProviderPatientsUseCase(this._repository);

  static const _window = Duration(days: 90);

  final ProviderDashboardRepository _repository;

  Future<Result<List<Patient>>> call({DateTime? now}) async {
    final result = await _callWithAppointments(now: now);
    return result.when(
      ok: (data) => Result.ok(data.patients),
      err: Result.err,
    );
  }

  /// Same paged walk as [call], but also returns every appointment seen
  /// within the window grouped by `patientId` — so a detail screen can show
  /// the exact appointment set the list already fetched instead of running
  /// its own separate ±90-day lookup.
  Future<Result<ProviderPatientsData>> callWithAppointments({
    DateTime? now,
  }) => _callWithAppointments(now: now);

  Future<Result<ProviderPatientsData>> _callWithAppointments({
    DateTime? now,
  }) async {
    final anchor = now ?? DateTime.now();
    final from = anchor.subtract(_window);
    final to = anchor.add(_window);

    final byPatient = <String, _Accumulator>{};
    String? cursor;

    do {
      final result = await _repository.getMyAppointments(
        from: from,
        to: to,
        cursor: cursor,
        // Backend caps `limit` at 50 (`ListDoctorAppointmentsQueryDto`) —
        // 100 here always 400'd; paging already walks `nextCursor` until
        // exhausted, so the smaller page size just means more round trips,
        // not fewer results.
        limit: 50,
      );

      if (result.isErr) {
        return Result.err(result.failureOrNull!);
      }
      final page = result.valueOrNull!;

      for (final appointment in page.items) {
        final acc = byPatient.putIfAbsent(
          appointment.patientId,
          () => _Accumulator(),
        );
        acc.absorb(appointment);
      }

      cursor = page.nextCursor;
    } while (cursor != null);

    final patients =
        byPatient.values.map((acc) => acc.toPatient(anchor)).toList()
          ..sort((a, b) => a.patientName.compareTo(b.patientName));

    final appointmentsByPatientId = <String, List<DoctorAppointment>>{
      for (final entry in byPatient.entries)
        entry.key: entry.value.appointments
          ..sort((a, b) => b.startAt.compareTo(a.startAt)),
    };

    return Result.ok(
      ProviderPatientsData(
        patients: patients,
        appointmentsByPatientId: appointmentsByPatientId,
      ),
    );
  }
}

/// The patient list plus every appointment seen for each patient within the
/// same ±90-day window, so a detail screen can reuse the list screen's own
/// fetch instead of re-querying `GET /v1/doctors/me/appointments` itself.
class ProviderPatientsData {
  const ProviderPatientsData({
    required this.patients,
    required this.appointmentsByPatientId,
  });

  final List<Patient> patients;
  final Map<String, List<DoctorAppointment>> appointmentsByPatientId;
}

class _Accumulator {
  String? patientId;
  String? patientName;
  String? patientPhone;
  DateTime? latestSeenCreatedAt;
  final List<DoctorAppointment> appointments = [];

  void absorb(DoctorAppointment appointment) {
    patientId = appointment.patientId;
    appointments.add(appointment);

    // Keep the name/phone from whichever appointment was created most
    // recently — the closest available proxy for "current" contact info,
    // since the backend has no separate patient-profile endpoint to refresh
    // it from.
    if (latestSeenCreatedAt == null ||
        appointment.createdAt.isAfter(latestSeenCreatedAt!)) {
      latestSeenCreatedAt = appointment.createdAt;
      patientName = appointment.patientName;
      patientPhone = appointment.patientPhone;
    }
  }

  Patient toPatient(DateTime now) {
    // "Last" (most recent past visit) can be any status — a completed or
    // even a cancelled slot still records that this patient was seen/booked
    // then. "Next" must be a real upcoming visit the patient will actually
    // show up to, i.e. still CONFIRMED — a CANCELLED or already-COMPLETED
    // row whose `startAt` happens to be in the future must never surface as
    // someone's next appointment.
    DateTime? last;
    DateTime? next;
    for (final appointment in appointments) {
      final startAt = appointment.startAt;
      if (!startAt.isAfter(now)) {
        if (last == null || startAt.isAfter(last)) last = startAt;
      } else if (appointment.isActionable) {
        if (next == null || startAt.isBefore(next)) next = startAt;
      }
    }

    return Patient(
      patientId: patientId!,
      patientName: patientName ?? '',
      patientPhone: patientPhone ?? '',
      lastAppointmentAt: last,
      nextAppointmentAt: next,
    );
  }
}
