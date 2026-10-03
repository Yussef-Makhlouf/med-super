import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/api_exception.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/appointments/data/datasources/remote/appointments_remote_datasource.dart';
import 'package:med_super/features/appointments/data/models/rescheduled_appointment_dto.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the backend one-step reschedule response', () {
    // Exact shape returned by RescheduleAppointmentUseCase (backend 894cba6).
    final dto = RescheduledAppointmentDto.fromJson({
      'status': 'CONFIRMED',
      'appointmentId': 'apt-new',
      'slotId': 'slot-new',
      'previousAppointmentId': 'apt-old',
    });

    final entity = dto.toEntity();
    expect(entity.appointmentId, 'apt-new');
    expect(entity.slotId, 'slot-new');
    expect(entity.previousAppointmentId, 'apt-old');
  });

  test('the dev mock speaks the same reschedule contract as the backend', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final dio = buildDioClient(
      storage: SecureStorageService(const FlutterSecureStorage()),
    );
    final remote = AppointmentsRemoteDatasource(dio);

    final hold = await remote.createHold(
      doctorClinicAffiliationId: 'aff-1',
      slotId: 'slot-old',
      patientId: 'patient-1',
    );
    final confirmed = await remote.confirmHold(
      hold.holdId,
      paymentMethod: AppointmentPaymentMethod.payAtClinic,
    );

    final rescheduled = await remote.reschedule(
      appointmentId: confirmed.appointmentId,
      newSlotId: 'slot-new',
    );
    expect(rescheduled.previousAppointmentId, confirmed.appointmentId);
    expect(rescheduled.slotId, 'slot-new');
    expect(rescheduled.appointmentId, isNot(confirmed.appointmentId));

    // The old appointment is RESCHEDULED now; a second attempt is a 422.
    final error = await remote
        .reschedule(appointmentId: confirmed.appointmentId, newSlotId: 'slot-x')
        .then<DioException?>((_) => null, onError: (Object e) => e as DioException);
    expect((error!.error! as ApiException).code, 'APPOINTMENT_NOT_RESCHEDULABLE');
  });
}
