import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/data/models/lab_booking_confirmation_dto.dart';

void main() {
  group('LabBookingConfirmationDto', () {
    test('fromJson parses all fields including fastingHours', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2001',
        'lab_name': 'Alpha Labs',
        'lab_address': '123 Main St',
        'date': '2026-08-20',
        'time': '10:00',
        'fasting_hours': 8,
      });

      expect(dto.bookingNumber, 'BK-2001');
      expect(dto.labName, 'Alpha Labs');
      expect(dto.labAddress, '123 Main St');
      expect(dto.date, DateTime.parse('2026-08-20'));
      expect(dto.time, '10:00');
      expect(dto.fastingHours, 8);
    });

    test('fromJson leaves fastingHours null when absent', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2002',
        'lab_name': 'Beta Labs',
        'lab_address': '456 Side St',
        'date': '2026-09-01',
        'time': '08:30',
      });

      expect(dto.fastingHours, isNull);
    });

    test('toEntity maps every field 1:1', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2001',
        'lab_name': 'Alpha Labs',
        'lab_address': '123 Main St',
        'date': '2026-08-20',
        'time': '10:00',
        'fasting_hours': 8,
      });

      final entity = dto.toEntity();

      expect(entity.bookingNumber, dto.bookingNumber);
      expect(entity.labName, dto.labName);
      expect(entity.labAddress, dto.labAddress);
      expect(entity.date, dto.date);
      expect(entity.time, dto.time);
      expect(entity.fastingHours, dto.fastingHours);
    });
  });
}
