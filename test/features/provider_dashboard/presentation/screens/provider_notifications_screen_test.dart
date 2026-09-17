import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_notifications_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('ProviderNotificationsScreen renders and handles card tap', (
    tester,
  ) async {
    final mockState = NotificationListState(
      items: [
        AppNotification(
          id: 'notif-1',
          templateCode: 'AppointmentConfirmed',
          title: 'تم تأكيد الموعد',
          body: 'تم تأكيد موعدك بنجاح.',
          createdAt: DateTime.now(),
          isUnread: true,
        ),
      ],
      nextCursor: null,
    );

    await pumpLocalizedWidget(
      tester,
      ProviderScope(
        overrides: [
          notificationListControllerProvider.overrideWith(
            () => _MockNotificationListController(mockState),
          ),
        ],
        child: const ProviderNotificationsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('التنبيهات'), findsWidgets);

    final notifTile = find.text('تم تأكيد الموعد');
    expect(notifTile, findsOneWidget);

    await tester.tap(notifTile);
    await tester.pumpAndSettle();
  });
}

class _MockNotificationListController extends NotificationListController {
  _MockNotificationListController(this._seed);

  final NotificationListState _seed;

  @override
  AsyncValue<NotificationListState> build() => AsyncData(_seed);
}
