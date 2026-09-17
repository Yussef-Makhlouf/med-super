/// Derives an in-app route from the backend's `template_code` + `data` payload.
///
/// The API stores deep-link hints in `data` (e.g. `{ appointmentId }`) but
/// never returns a ready-made route string — that mapping lives here.
String? notificationDeepLink({
  required String templateCode,
  required Map<String, dynamic>? data,
  required bool isProvider,
}) {
  switch (templateCode) {
    case 'AppointmentConfirmed':
    case 'AppointmentCancelled':
      return isProvider ? '/provider/appointments' : '/patient/appointments';
    case 'NewAppointmentBookedForDoctor':
    case 'AppointmentCancelledForDoctor':
    case 'AppointmentRescheduledForDoctor':
      final appointmentId = data?['appointmentId'];
      if (appointmentId is String && appointmentId.isNotEmpty) {
        return '/provider/appointments?openAppointmentId=$appointmentId';
      }
      return '/provider/appointments';
    case 'LabResultReady':
    case 'CriticalLabResult':
      final labOrderId = data?['labOrderId'];
      if (labOrderId is String && labOrderId.isNotEmpty) {
        return '/patient/orders/lab/$labOrderId';
      }
      return '/patient/orders';
    case 'PrescriptionUploaded':
    case 'PrescriptionAccepted':
    case 'PrescriptionRejected':
      return '/patient/orders';
    case 'PharmacyOrderAccepted':
    case 'PharmacyOrderQuoted':
    case 'PharmacyOrderRejected':
      final pharmacyOrderId = data?['pharmacyOrderId'];
      if (pharmacyOrderId is String && pharmacyOrderId.isNotEmpty) {
        return '/patient/orders/$pharmacyOrderId';
      }
      return '/patient/orders';
    default:
      return null;
  }
}
