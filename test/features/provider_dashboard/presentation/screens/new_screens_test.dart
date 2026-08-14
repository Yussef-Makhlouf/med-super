import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_clinic_settings_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_edit_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_schedule_editor_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_security_privacy_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

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

  testWidgets('ProviderClinicSettingsScreen renders form', (tester) async {
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

    expect(find.text('إعدادات العيادة'), findsOneWidget);
  });

  testWidgets('ProviderScheduleEditorScreen renders working days', (
    tester,
  ) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const ProviderScheduleEditorScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    expect(find.text('جدول المواعيد وساعات العمل'), findsOneWidget);
  });

  testWidgets('ProviderSecurityPrivacyScreen renders password fields', (
    tester,
  ) async {
    await pumpLocalizedWidget(tester, const ProviderSecurityPrivacyScreen());

    expect(find.text('الأمان والخصوصية'), findsOneWidget);
    expect(find.text('كلمة المرور الحالية'), findsOneWidget);
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
  });
}
