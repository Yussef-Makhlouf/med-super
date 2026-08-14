import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/appointment.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/patient.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointment_detail_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patient_detail_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('ProviderAppointmentDetailScreen renders appointment info', (
    tester,
  ) async {
    final appointment = Appointment(
      id: 'apt-101',
      patientName: 'محمد أحمد',
      patientAvatarUrl: null,
      scheduledStart: DateTime(2026, 8, 14, 10, 0),
      scheduledEnd: DateTime(2026, 8, 14, 10, 30),
      locationStatus: 'في العيادة',
      medId: 'MED-9988',
      status: AppointmentStatus.confirmed,
    );

    await pumpLocalizedWidget(
      tester,
      ProviderAppointmentDetailScreen(appointment: appointment),
    );

    expect(find.text('تفاصيل الموعد'), findsOneWidget);
    expect(find.text('محمد أحمد'), findsOneWidget);
    expect(find.text('رقم الملف: MED-9988'), findsOneWidget);
    expect(find.text('سجل حالة الموعد'), findsOneWidget);
  });

  testWidgets('ProviderPatientDetailScreen renders patient snapshot', (
    tester,
  ) async {
    final patient = Patient(
      id: 'pat-101',
      name: 'عبدالله خالد',
      medId: 'MED-5544',
      avatarUrl: null,
      status: 'مؤكد',
      nextAppointment: DateTime(2026, 8, 15, 14, 0),
    );

    await pumpLocalizedWidget(
      tester,
      ProviderPatientDetailScreen(patient: patient),
    );

    expect(find.text('الملف الطبي للمريض'), findsOneWidget);
    expect(find.text('عبدالله خالد'), findsOneWidget);
    expect(find.text('رقم الملف (MED): MED-5544'), findsOneWidget);
  });
}
