import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_dashboard_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletDashboardScreen renders balance card, quick actions, and transaction list', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletDashboardScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    // Let real async network calls/Riverpod state updates resolve
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('المحفظة الرقمية'), findsAtLeastNWidgets(1));
    expect(find.text('الرصيد المتاح'), findsOneWidget);
    expect(find.text('إيداع'), findsOneWidget);
    expect(find.text('تحويل'), findsOneWidget);
    expect(find.text('بطاقات مرتبطة'), findsOneWidget);
    expect(find.text('سجل المعاملات'), findsOneWidget);
  });
}
