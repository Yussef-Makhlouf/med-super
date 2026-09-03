import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/data/models/lab_booking_confirmation_dto.dart';

void main() {
  group('LabBookingConfirmationDto', () {
    test('fromJson parses all fields', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2001',
        'lab_name': 'Alpha Labs',
        'lab_address': '123 Main St',
        'expected_response_hours': 3,
      });

      expect(dto.bookingNumber, 'BK-2001');
      expect(dto.labName, 'Alpha Labs');
      expect(dto.labAddress, '123 Main St');
      expect(dto.expectedResponseHours, 3);
    });

    test('fromJson defaults expectedResponseHours to 2 when absent', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2002',
        'lab_name': 'Beta Labs',
        'lab_address': '456 Side St',
      });

      expect(dto.expectedResponseHours, 2);
    });

    test('toEntity maps every field 1:1', () {
      final dto = LabBookingConfirmationDto.fromJson(const {
        'booking_number': 'BK-2001',
        'lab_name': 'Alpha Labs',
        'lab_address': '123 Main St',
        'expected_response_hours': 3,
      });

      final entity = dto.toEntity();

      expect(entity.bookingNumber, dto.bookingNumber);
      expect(entity.labName, dto.labName);
      expect(entity.labAddress, dto.labAddress);
      expect(entity.expectedResponseHours, dto.expectedResponseHours);
    });
  });
}
