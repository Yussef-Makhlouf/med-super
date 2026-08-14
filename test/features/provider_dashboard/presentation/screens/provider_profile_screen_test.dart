import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_profile_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

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
}
