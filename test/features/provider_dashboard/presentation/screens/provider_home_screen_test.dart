import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets(
    'ProviderHomeScreen renders the calendar, week strip, and legend',
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

      expect(find.text('الجدول'), findsOneWidget);
      // Week strip renders 7 day tiles (day-of-month numbers).
      final now = DateTime.now();
      expect(find.text(now.day.toString()), findsWidgets);
      // Legend row.
      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('محجوز'), findsOneWidget);

      // Tapping a different day tile updates the selected date without
      // throwing — exact slot content is randomly generated per day.
      await tester.tap(find.byKey(const Key('providerCalendarDayTile-2')));
      await tester.pumpAndSettle();
    },
  );
}
