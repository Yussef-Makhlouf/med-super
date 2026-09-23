import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';
import 'package:med_super/features/appointments/domain/entities/online_payment_initiation.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class InitiateOnlinePaymentUseCase {
  const InitiateOnlinePaymentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<OnlinePaymentInitiation>> call(
    String holdId, {
    required AppointmentPaymentMethod method,
    required PaymentCustomerInfo customer,
    String? paymentAmount,
  }) => _repository.initiateOnlinePayment(
    holdId,
    method: method,
    customer: customer,
    paymentAmount: paymentAmount,
  );
}
