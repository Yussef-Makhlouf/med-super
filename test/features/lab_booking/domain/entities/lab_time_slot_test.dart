import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_time_slot.dart';

void main() {
  test('stores time and availability as given', () {
    const slot = LabTimeSlot(time: '09:30', isAvailable: true);

    expect(slot.time, '09:30');
    expect(slot.isAvailable, isTrue);
  });

  test('supports an unavailable slot', () {
    const slot = LabTimeSlot(time: '16:30', isAvailable: false);

    expect(slot.isAvailable, isFalse);
  });
}
