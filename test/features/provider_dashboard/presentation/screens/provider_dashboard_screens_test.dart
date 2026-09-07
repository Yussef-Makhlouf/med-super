import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_clinic_settings_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_edit_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_schedule_editor_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// Renamed from `new_screens_test.dart` (2026-09-02) — that file also tested
/// `ProviderSecurityPrivacyScreen`, which was never actually built (the
/// import didn't resolve to any file in `lib/`). No security/privacy screen
/// exists for the provider dashboard and there's no product decision to add
/// one, so that test case was removed rather than fabricating the screen
/// just to make it pass — the three screens below are real.
void main() {
  testWidgets('ProviderEditProfileScreen renders form and submits', (
    tester,
  ) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const ProviderEditProfileScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.text('المعلومات الشخصية'), findsOneWidget);
  });

  // Both screens below pump the real Dio stack against `MockInterceptor`, so
  // they exercise the actual doctor-scoped routes and DTO parsing end to end
  // — not a stubbed repository (File 12 Part 49.2/49.5).
  testWidgets('ProviderClinicSettingsScreen lists the doctor clinics', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const ProviderClinicSettingsScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // The two seeded branches belong to different clinics, so the AppBar
    // falls back to the generic title rather than naming just one of them.
    expect(find.text('عياداتي'), findsOneWidget);
    // Seeded by the mock's `GET /v1/doctors/me/clinics` in the real shape —
    // the list shows each branch as a row titled by its city (branches have
    // no name of their own), with the clinic name in the subtitle.
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('الإسكندرية'), findsOneWidget);
    expect(find.textContaining('عيادة النيل التخصصية'), findsOneWidget);
    expect(find.textContaining('مركز الإسكندرية الطبي'), findsOneWidget);
    // The full form (consult fee, delete) is not shown until a row is tapped.
    expect(find.widgetWithText(TextFormField, 'سعر الكشف (EGP)'), findsNothing);
    expect(find.text('حذف الفرع'), findsNothing);
    // Adding a branch is offered at the screen level.
    expect(find.text('إضافة فرع'), findsOneWidget);

    // Tapping a row opens the edit sheet with the full form.
    await tester.tap(find.text('القاهرة'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'سعر الكشف (EGP)'), findsOneWidget);
    expect(find.text('حذف الفرع'), findsOneWidget);
    // Save starts disabled — nothing has changed yet.
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'حفظ التغييرات'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('ProviderClinicSettingsScreen adds a branch via the FAB', (
    tester,
  ) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const ProviderClinicSettingsScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    final addFab = find.widgetWithText(FloatingActionButton, 'إضافة فرع');
    expect(addFab, findsOneWidget);
    await tester.ensureVisible(addFab);
    await tester.pumpAndSettle();
    await tester.tap(addFab);
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    await tester.enterText(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextFormField, 'هاتف الفرع'),
      ),
      '+20233330000',
    );
    await tester.enterText(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextFormField, 'العنوان'),
      ),
      '3 New St',
    );
    await tester.enterText(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextFormField, 'المدينة'),
      ),
      'Mansoura',
    );
    await tester.enterText(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextFormField, 'رمز المنطقة'),
      ),
      'MNS',
    );
    await tester.enterText(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(TextFormField, 'سعر الكشف (EGP)'),
      ),
      '200',
    );
    await tester.runAsync(() async {
      await tester.tap(
        find.descendant(
          of: sheet,
          matching: find.widgetWithText(FilledButton, 'إضافة فرع'),
        ),
      );
      for (
        var i = 0;
        i < 20 && find.text('تمت إضافة الفرع.').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));
      }
    });

    // `POST /v1/doctors/me/clinics/{clinicId}/branches` succeeded and the
    // list was refetched from the server's own response, per the doc
    // comment on `_save` — never trust the local copy after a write.
    expect(find.text('تمت إضافة الفرع.'), findsOneWidget);
  });

  testWidgets(
    'ProviderClinicSettingsScreen shows BRANCH_HAS_BOOKINGS when deleting a booked branch',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderClinicSettingsScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // The Nile branch (Cairo) has CONFIRMED appointments seeded against
      // it, so deleting it must be blocked with the backend's own Arabic
      // conflict message, not silently succeed. Open its row (titled by
      // city, not clinic name) first — the delete button now lives inside
      // the edit sheet, not the list row.
      await tester.tap(find.text('القاهرة').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف الفرع'));
      await tester.pumpAndSettle();

      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      expect(confirmButton, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(confirmButton);
        for (
          var i = 0;
          i < 20 && find.textContaining('مواعيد محجوزة').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump(const Duration(milliseconds: 20));
        }
      });

      expect(find.textContaining('مواعيد محجوزة'), findsOneWidget);
      // The branch is still there — nothing was deleted.
      expect(find.textContaining('عيادة النيل التخصصية'), findsWidgets);
    },
  );

  testWidgets('ProviderScheduleEditorScreen lists weekly availability', (
    tester,
  ) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const ProviderScheduleEditorScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.text('جدول المواعيد'), findsOneWidget);
    // The "future generation only" warning must always be visible — a doctor
    // editing hours must never believe booked appointments moved with them.
    expect(
      find.textContaining('تسري التغييرات على الأوقات الجديدة فقط'),
      findsOneWidget,
    );
  });
}
