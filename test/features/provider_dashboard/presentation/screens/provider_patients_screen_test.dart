import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patients_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// Exercises the real Dio stack against `MockInterceptor` (File 12 Part
/// 49.7's `GET /v1/doctors/me/appointments`, seeded by
/// `_seedDoctorAppointments()` in `mock_responses.dart`), so this covers the
/// actual paging/dedup/DTO-parsing path — not a stubbed repository.
void main() {
  testWidgets(
    'ProviderPatientsScreen lists deduped real patients and filters by search',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderPatientsScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // The seed has 6 appointments across 6 distinct patientIds — no
      // duplicate patientId in the fixture, so this also implicitly covers
      // "no accidental over-merging", while the usecase-level tests cover
      // the actual dedup-by-repeated-patientId behaviour directly.
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('منى حسن'), findsOneWidget);
      expect(find.text('فاطمة الشهري'), findsOneWidget);
      expect(find.text('نورة العمري'), findsOneWidget);
      expect(find.text('محمد الغامدي'), findsOneWidget);
      expect(find.text('6 مرضى'), findsOneWidget);

      // Search filters client-side over the already-fetched list.
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'سارة');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('أحمد محمود'), findsNothing);
      expect(find.text('1 مرضى'), findsOneWidget);

      // Clearing the query restores the full list.
      await tester.enterText(searchField, '');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('6 مرضى'), findsOneWidget);
    },
  );

  testWidgets(
    'the اليوم filter chip narrows to patients whose next appointment is today',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderPatientsScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      await tester.tap(find.text('اليوم'));
      await tester.pump();
      await tester.pump();

      // The seed's "today" appointments (apt-1 Ahmed, apt-2 Sara) sit at
      // fixed wall-clock hours, so whether they still count as this
      // patient's *next* (future) appointment depends on what time the test
      // happens to run — `nextAppointmentAt` only holds true future
      // appointments, so an already-passed "today" slot correctly has none.
      // What's run-time-independent: apt-5 (Noura, tomorrow) and apt-6
      // (Mohamed, +2 days) are always excluded from "today", and apt-3
      // (Mona, COMPLETED) / apt-4 (Fatma, CANCELLED) are always in the past
      // with no next appointment at all either way.
      expect(find.text('نورة العمري'), findsNothing);
      expect(find.text('محمد الغامدي'), findsNothing);
      expect(find.text('منى حسن'), findsNothing);
      expect(find.text('فاطمة الشهري'), findsNothing);

      await tester.tap(find.text('هذا الأسبوع'));
      await tester.pump();
      await tester.pump();

      // "This week" (today..+7d) always includes tomorrow and +2 days,
      // regardless of what time the test runs.
      expect(find.text('نورة العمري'), findsOneWidget);
      expect(find.text('محمد الغامدي'), findsOneWidget);

      await tester.tap(find.text('الكل'));
      await tester.pump();
      await tester.pump();
      expect(find.text('6 مرضى'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a patient opens the detail screen with that patient\'s own appointment set',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderPatientsScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      await tester.tap(find.text('سارة علي'));
      await tester.pumpAndSettle();

      expect(find.text('الملف الطبي للمريض'), findsOneWidget);
      // The detail screen reuses `providerPatientsDataProvider`'s already-
      // fetched appointment grouping rather than re-querying, so Sara's
      // single seeded appointment (apt-2, at her own clinic) shows up here
      // with no extra network call needed to resolve it.
      expect(find.text('عيادة النيل التخصصية'), findsWidgets);
    },
  );
}
