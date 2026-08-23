import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_transaction_detail_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletTransactionDetailScreen renders transaction breakdown', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletTransactionDetailScreen(transactionId: 'tx-101'),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('تفاصيل المعاملة'), findsAtLeastNWidgets(1));
    expect(find.text('المبلغ المدفوع'), findsOneWidget);
    expect(find.text('معلومات العملية'), findsOneWidget);
    expect(find.text('تحميل الإيصال'), findsOneWidget);
  });
}
