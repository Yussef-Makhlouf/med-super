import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';

void main() {
  testWidgets(
    'ProviderHomeScreen renders, interacts with segment tabs, and opens FAB sheet',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: const MaterialApp(home: ProviderHomeScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.text('مواعيد اليوم'), findsOneWidget);
      expect(find.text('القادمة'), findsOneWidget);

      // Tap segment tab 'المنتهية'
      final completedTab = find.text('المنتهية');
      expect(completedTab, findsOneWidget);
      await tester.tap(completedTab);
      await tester.pumpAndSettle();

      // Tap FAB button to open Add Appointment bottom sheet
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('إضافة موعد جديد'), findsOneWidget);
    },
  );
}
