import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_account_profile.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_notification.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/patient.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patient_detail_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// Minimal repository stub — the screens under test read through the real
/// use-case providers, so overriding the repository once covers all of them.
class _StubRepo implements ProviderDashboardRepository {
  _StubRepo({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Future<Result<DoctorAppointment>> getMyAppointment(String appointmentId) async =>
      Result.ok(appointment);

  @override
  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) async => Result.ok(DoctorAppointmentPage(items: [appointment]));

  @override
  Future<Result<DoctorAccountProfile>> getDoctorAccount() async =>
      const Result.ok(
        DoctorAccountProfile(
          id: 'doc-001',
          name: 'Amr Adel',
          specialty: 'Cardiology',
          licenseNumber: 'LIC-001',
          phone: '+201000000000',
        ),
      );

  @override
  Future<Result<List<DoctorClinic>>> getMyClinics() async =>
      const Result.ok([]);

  @override
  Future<Result<List<DoctorNotification>>> getNotifications() async =>
      const Result.ok([]);

  @override
  Future<Result<List<DoctorScheduleTemplate>>> getMyScheduleTemplates({
    String? affiliationId,
  }) async => const Result.ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DoctorAppointment _appointment({
  DoctorAppointmentStatus status = DoctorAppointmentStatus.confirmed,
}) => DoctorAppointment(
  appointmentId: 'apt-101',
  status: status,
  slotId: 'slot-1',
  startAt: DateTime.utc(2026, 8, 14, 10),
  endAt: DateTime.utc(2026, 8, 14, 10, 30),
  doctorClinicAffiliationId: 'aff-1',
  clinicId: 'clinic-1',
  clinicName: 'عيادة النيل التخصصية',
  clinicBranchId: 'branch-1',
  clinicBranchPhone: '+20221230000',
  clinicAddressLine1: '12 شارع التحرير',
  clinicCity: 'القاهرة',
  ianaTimezone: 'Africa/Cairo',
  patientId: 'pat-101',
  patientName: 'محمد أحمد',
  patientPhone: '+201009998887',
  createdAt: DateTime.utc(2026, 8, 1),
);

void main() {
  testWidgets('appointment detail renders the real patient and clinic fields', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const ProviderAppointmentDetailScreen(appointmentId: 'apt-101'),
      overrides: [
        providerDashboardRepositoryProvider.overrideWithValue(
          _StubRepo(appointment: _appointment()),
        ),
      ],
    );

    expect(find.text('محمد أحمد'), findsOneWidget);
    expect(find.text('+201009998887'), findsOneWidget);
    expect(find.text('Africa/Cairo'), findsOneWidget);
    // A CONFIRMED appointment offers both provider actions.
    expect(find.text('تغيير الموعد'), findsOneWidget);
    expect(find.text('إلغاء الموعد'), findsOneWidget);
  });

  testWidgets('a cancelled appointment offers no provider actions', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const ProviderAppointmentDetailScreen(appointmentId: 'apt-101'),
      overrides: [
        providerDashboardRepositoryProvider.overrideWithValue(
          _StubRepo(
            appointment: _appointment(
              status: DoctorAppointmentStatus.cancelled,
            ),
          ),
        ),
      ],
    );

    expect(find.text('ملغى'), findsOneWidget);
    expect(find.text('تغيير الموعد'), findsNothing);
    expect(find.text('إلغاء الموعد'), findsNothing);
  });

  testWidgets('ProviderPatientDetailScreen renders patient snapshot', (
    tester,
  ) async {
    final patient = Patient(
      patientId: 'pat-101',
      patientName: 'عبدالله خالد',
      patientPhone: '+201009998887',
      nextAppointmentAt: DateTime(2026, 8, 15, 14, 0),
    );

    await pumpLocalizedWidget(
      tester,
      ProviderPatientDetailScreen(patient: patient),
      overrides: [
        providerDashboardRepositoryProvider.overrideWithValue(
          _StubRepo(appointment: _appointment()),
        ),
      ],
    );

    expect(find.text('الملف الطبي للمريض'), findsOneWidget);
    expect(find.text('عبدالله خالد'), findsOneWidget);
    expect(find.text('+201009998887'), findsWidgets);
  });
}
