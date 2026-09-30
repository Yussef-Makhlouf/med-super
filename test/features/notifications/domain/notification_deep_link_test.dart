import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/notifications/notification_priority.dart';
import 'package:med_super/core/notifications/notification_priority_router.dart';
import 'package:med_super/features/notifications/domain/utils/notification_deep_link.dart';

void main() {
  test('backend tier preserves safety-critical foreground priority', () {
    expect(
      NotificationPriorityRouter().classify({'tier': 'SAFETY_CRITICAL'}),
      NotificationPriority.safetyCritical,
    );
  });
  test('pharmacy status opens the current patient order', () {
    expect(
      notificationDeepLink(
        templateCode: 'ProviderPharmacyOrderStatusChanged',
        data: {'pharmacyOrderId': 'order-1', 'status': 'OUT_FOR_DELIVERY'},
        isProvider: false,
      ),
      '/patient/orders/order-1',
    );
  });

  test('provider pharmacy status stays on provider surface', () {
    expect(
      notificationDeepLink(
        templateCode: 'ProviderPharmacyOrderStatusChanged',
        data: {'pharmacyOrderId': 'order-1'},
        isProvider: true,
      ),
      '/provider/patients',
    );
  });

  test('patient appointment opens a real detail route', () {
    expect(
      notificationDeepLink(
        templateCode: 'AppointmentConfirmed',
        data: {'appointmentId': 'appointment-1'},
        isProvider: false,
      ),
      '/patient/home/appointments/appointment-1',
    );
  });

  test('assistant appointment opens provider appointment queue', () {
    expect(
      notificationDeepLink(
        templateCode: 'NewAppointmentBookedForAssistant',
        data: {'appointmentId': 'appointment-1'},
        isProvider: true,
      ),
      '/provider/appointments?openAppointmentId=appointment-1',
    );
  });

  test('clinic handover staff alert opens the linked appointment', () {
    expect(
      notificationDeepLink(
        templateCode: 'PharmacyOrderOnWayToClinicForStaff',
        data: {'appointmentId': 'appointment-1'},
        isProvider: true,
      ),
      '/provider/appointments?openAppointmentId=appointment-1',
    );
  });

  test('lab status uses patient lab detail and provider patient list', () {
    expect(
      notificationDeepLink(
        templateCode: 'LabOrderStatusChanged',
        data: {'labOrderId': 'lab-1'},
        isProvider: false,
      ),
      '/patient/orders/lab/lab-1',
    );
    expect(
      notificationDeepLink(
        templateCode: 'LabResultReadyForProvider',
        data: {'labOrderId': 'lab-1'},
        isProvider: true,
      ),
      '/provider/patients',
    );
  });

  test('unroutable dashboard-only event has no mobile destination', () {
    expect(
      notificationDeepLink(
        templateCode: 'NewPharmacyOrderForStaff',
        data: {'pharmacyOrderId': 'order-1'},
        isProvider: false,
      ),
      isNull,
    );
  });
}
