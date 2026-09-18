/// Everything the booking flow needs, carried via `GoRouterState.extra` from
/// the doctor-detail screen (File 10 §2.3's hold request needs
/// `doctorClinicAffiliationId`+`slotId`; the rest is display-only).
class BookingRequest {
  const BookingRequest({
    required this.doctorClinicAffiliationId,
    required this.slotId,
    required this.doctorName,
    required this.specialty,
    required this.dayLabel,
    required this.timeLabel,
    required this.consultationFee,
    required this.currency,
  });

  final String doctorClinicAffiliationId;
  final String slotId;
  final String doctorName;
  final String specialty;
  final String dayLabel;
  final String timeLabel;
  final int consultationFee;
  final String currency;
}
