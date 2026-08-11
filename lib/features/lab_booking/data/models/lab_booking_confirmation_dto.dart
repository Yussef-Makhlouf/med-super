import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';

class LabBookingConfirmationDto {
  const LabBookingConfirmationDto({
    required this.bookingNumber,
    required this.labName,
    required this.labAddress,
    required this.date,
    required this.time,
    this.fastingHours,
  });

  final String bookingNumber;
  final String labName;
  final String labAddress;
  final DateTime date;
  final String time;
  final int? fastingHours;

  factory LabBookingConfirmationDto.fromJson(Map<String, dynamic> json) =>
      LabBookingConfirmationDto(
        bookingNumber: json['booking_number'] as String,
        labName: json['lab_name'] as String,
        labAddress: json['lab_address'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        fastingHours: json['fasting_hours'] as int?,
      );

  LabBookingConfirmation toEntity() => LabBookingConfirmation(
    bookingNumber: bookingNumber,
    labName: labName,
    labAddress: labAddress,
    date: date,
    time: time,
    fastingHours: fastingHours,
  );
}
