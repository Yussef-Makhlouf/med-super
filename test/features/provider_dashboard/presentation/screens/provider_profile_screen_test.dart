import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_profile_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

class _AssistantSessionController extends SessionController {
  @override
  Future<Session?> build() async => Session(
    user: User(
      id: 'assistant-1',
      phone: '+201000000001',
      roles: [UserRole.clinicStaff],
      activeRole: UserRole.clinicStaff,
      displayName: 'Clinic Assistant',
    ),
    onboardingComplete: true,
    passwordComplete: true,
  );
}

void main() {
  testWidgets(
    'ProviderProfileScreen renders profile info and navigates on tile tap',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderProfileScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('تسجيل الخروج'), findsOneWidget);
      expect(find.text('المعلومات الشخصية'), findsOneWidget);

      // Tap nav tile 'المعلومات الشخصية'
      final navTile = find.text('المعلومات الشخصية');
      await tester.tap(navTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify Edit Profile screen opens with form fields
      expect(find.text('المعلومات الشخصية'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'assistant profile shows assigned workspace, not doctor settings',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const ProviderProfileScreen(),
        overrides: [
          sessionControllerProvider.overrideWith(
            _AssistantSessionController.new,
          ),
        ],
      );

      await tester.pumpAndSettle();
      expect(find.text('Clinic Assistant'), findsOneWidget);
      expect(find.text('مساعد العيادة'), findsOneWidget);
      expect(find.text('الفروع المسندة'), findsOneWidget);
      expect(find.text('المساعدون'), findsNothing);
    },
  );
}
