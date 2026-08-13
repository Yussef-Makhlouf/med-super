import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

void main() {
  test('LabBookingConfirmation stores all required fields', () {
    const confirmation = LabBookingConfirmation(
      bookingNumber: 'BK-1001',
      labName: 'Alpha Labs',
      labAddress: '123 Main St',
      expectedResponseHours: 2,
    );

    expect(confirmation.bookingNumber, 'BK-1001');
    expect(confirmation.labName, 'Alpha Labs');
    expect(confirmation.labAddress, '123 Main St');
    expect(confirmation.expectedResponseHours, 2);
  });

  test('LabBookingConfirmation stores a different expectedResponseHours', () {
    const confirmation = LabBookingConfirmation(
      bookingNumber: 'BK-1002',
      labName: 'Beta Labs',
      labAddress: '456 Side St',
      expectedResponseHours: 3,
    );

    expect(confirmation.expectedResponseHours, 3);
  });
}
