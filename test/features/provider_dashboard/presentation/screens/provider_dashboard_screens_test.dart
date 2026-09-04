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

    expect(find.text('عياداتي'), findsOneWidget);
    // Seeded by the mock's `GET /v1/doctors/me/clinics` in the real shape.
    expect(find.text('عيادة النيل التخصصية'), findsOneWidget);
    expect(find.text('مركز الإسكندرية الطبي'), findsOneWidget);
  });

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

    expect(find.text('أوقات عملي'), findsOneWidget);
    // The "future generation only" warning must always be visible — a doctor
    // editing hours must never believe booked appointments moved with them.
    expect(
      find.textContaining('تسري التغييرات على الأوقات الجديدة فقط'),
      findsOneWidget,
    );
  });
}
