import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_notification.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_notifications_screen.dart';

void main() {
  testWidgets('ProviderNotificationsScreen renders and handles card tap',
      (tester) async {
    final mockNotifications = [
      DoctorNotification(
        id: 'notif-1',
        type: NotificationType.newBookingRequest,
        title: 'طلب حجز جديد',
        subtitle: 'قام سارة المحمد بحجز موعد جديد',
        createdAt: DateTime.now(),
        isUnread: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorNotificationsProvider
              .overrideWith((ref) async => mockNotifications),
        ],
        child: const MaterialApp(
          home: ProviderNotificationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('التنبيهات'), findsWidgets);

    final notifTile = find.text('طلب حجز جديد');
    expect(notifTile, findsOneWidget);

    await tester.tap(notifTile);
    await tester.pumpAndSettle();
  });
}
