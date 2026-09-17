import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';
import 'package:med_super/features/appointments/domain/entities/confirmed_appointment.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class ConfirmAppointmentUseCase {
  const ConfirmAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<ConfirmedAppointment>> call(
    String holdId, {
    AppointmentPaymentMethod paymentMethod =
        AppointmentPaymentMethod.payAtClinic,
  }) => _repository.confirmHold(holdId, paymentMethod: paymentMethod);
}
