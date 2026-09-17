import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

void main() {
  test('LabBookingConfirmation stores all required fields', () {
    const confirmation = LabBookingConfirmation(
      orderId: '11111111-1111-4111-8111-111111111111',
      branchName: 'Alpha Labs',
      branchAddress: '123 Main St',
    );

    expect(confirmation.orderId, '11111111-1111-4111-8111-111111111111');
    expect(confirmation.branchName, 'Alpha Labs');
    expect(confirmation.branchAddress, '123 Main St');
  });

  test('LabBookingConfirmation stores a different order', () {
    const confirmation = LabBookingConfirmation(
      orderId: '22222222-2222-4222-8222-222222222222',
      branchName: 'Beta Labs',
      branchAddress: '456 Side St',
    );

    expect(confirmation.orderId, '22222222-2222-4222-8222-222222222222');
  });
}
