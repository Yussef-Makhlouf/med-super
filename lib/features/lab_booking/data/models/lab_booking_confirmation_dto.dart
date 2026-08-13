import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

class LabBookingConfirmationDto {
  const LabBookingConfirmationDto({
    required this.bookingNumber,
    required this.labName,
    required this.labAddress,
    required this.expectedResponseHours,
  });

  final String bookingNumber;
  final String labName;
  final String labAddress;
  final int expectedResponseHours;

  factory LabBookingConfirmationDto.fromJson(Map<String, dynamic> json) =>
      LabBookingConfirmationDto(
        bookingNumber: json['booking_number'] as String,
        labName: json['lab_name'] as String,
        labAddress: json['lab_address'] as String,
        expectedResponseHours: json['expected_response_hours'] as int? ?? 2,
      );

  LabBookingConfirmation toEntity() => LabBookingConfirmation(
    bookingNumber: bookingNumber,
    labName: labName,
    labAddress: labAddress,
    expectedResponseHours: expectedResponseHours,
  );
}
