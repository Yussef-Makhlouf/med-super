/// Derives an in-app route from the backend's `template_code` + `data` payload.
///
/// The API stores deep-link hints in `data` (e.g. `{ appointmentId }`) but
/// never returns a ready-made route string — that mapping lives here.
String? notificationDeepLink({
  required String templateCode,
  required Map<String, dynamic>? data,
  required bool isProvider,
}) {
  String? patientOrderRoute(String key, {bool laboratory = false}) {
    if (isProvider) return '/provider/patients';
    final id = data?[key];
    if (id is String && id.isNotEmpty) {
      final encoded = Uri.encodeComponent(id);
      return laboratory
          ? '/patient/orders/lab/$encoded'
          : '/patient/orders/$encoded';
    }
    return '/patient/orders';
  }

  switch (templateCode) {
    case 'AppointmentConfirmed':
    case 'AppointmentCancelled':
      if (isProvider) return '/provider/appointments';
      final appointmentId = data?['appointmentId'];
      return appointmentId is String && appointmentId.isNotEmpty
          ? '/patient/home/appointments/${Uri.encodeComponent(appointmentId)}'
          : '/patient/appointments';
    case 'NewAppointmentBookedForDoctor':
    case 'AppointmentCancelledForDoctor':
    case 'AppointmentRescheduledForDoctor':
    case 'NewAppointmentBookedForAssistant':
    case 'AppointmentCancelledForAssistant':
    case 'AppointmentRescheduledForAssistant':
    case 'PharmacyOrderOnWayToClinicForStaff':
      if (!isProvider) return '/patient/notifications';
      final appointmentId = data?['appointmentId'];
      if (appointmentId is String && appointmentId.isNotEmpty) {
        return '/provider/appointments?openAppointmentId=${Uri.encodeQueryComponent(appointmentId)}';
      }
      return '/provider/appointments';
    case 'LabResultReady':
    case 'CriticalLabResult':
    case 'ProviderLabOrderCreated':
    case 'LabOrderStatusChanged':
    case 'LabResultReadyForProvider':
      return patientOrderRoute('labOrderId', laboratory: true);
    case 'PrescriptionUploaded':
    case 'PrescriptionAccepted':
    case 'PrescriptionRejected':
    case 'ProviderPrescriptionCreated':
    case 'ProviderPrescriptionPendingApproval':
    case 'ProviderPrescriptionApproved':
    case 'ProviderPrescriptionRejected':
    case 'ProviderPrescriptionStatusChanged':
      return isProvider ? '/provider/patients' : '/patient/orders';
    case 'PharmacyOrderAccepted':
    case 'PharmacyOrderQuoted':
    case 'PharmacyOrderRejected':
    case 'ProviderPharmacyOrderCreated':
    case 'ProviderPharmacyOrderStatusChanged':
      return patientOrderRoute('pharmacyOrderId');
    case 'PaymentCaptured':
    case 'PaymentFailed':
    case 'RefundIssued':
    case 'PaymentAutoRefunded':
      return isProvider ? '/provider/notifications' : '/patient/appointments';
    case 'WalletToppedUp':
      return isProvider ? '/provider/notifications' : '/patient/home/wallet';
    default:
      return null;
  }
}
