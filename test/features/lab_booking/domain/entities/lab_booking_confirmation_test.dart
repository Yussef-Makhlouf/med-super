import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

void main() {
  test('LabBookingConfirmation stores all required fields and no fasting', () {
    final date = DateTime(2026, 8, 20);
    final confirmation = LabBookingConfirmation(
      bookingNumber: 'BK-1001',
      labName: 'Alpha Labs',
      labAddress: '123 Main St',
      date: date,
      time: '10:00',
    );

    expect(confirmation.bookingNumber, 'BK-1001');
    expect(confirmation.labName, 'Alpha Labs');
    expect(confirmation.labAddress, '123 Main St');
    expect(confirmation.date, date);
    expect(confirmation.time, '10:00');
    expect(confirmation.fastingHours, isNull);
  });

  test('LabBookingConfirmation stores fastingHours when provided', () {
    final confirmation = LabBookingConfirmation(
      bookingNumber: 'BK-1002',
      labName: 'Beta Labs',
      labAddress: '456 Side St',
      date: DateTime(2026, 9, 1),
      time: '08:30',
      fastingHours: 8,
    );

    expect(confirmation.fastingHours, 8);
  });
}
