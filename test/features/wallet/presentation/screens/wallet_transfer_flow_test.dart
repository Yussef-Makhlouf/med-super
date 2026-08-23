import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_transfer_confirm_screen.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_transfer_destination_screen.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_transfer_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletTransferScreen renders the transfer stepper step 1 with amount chips', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletTransferScreen(),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('تحويل'), findsAtLeastNWidgets(1));
    expect(find.text('حدد المبلغ المراد تحويله'), findsOneWidget);
    expect(find.text('1000 ج.م'), findsOneWidget);
  });

  testWidgets('WalletTransferDestinationScreen renders the linked bank account', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const WalletTransferDestinationScreen(amount: 500),
    );

    expect(find.text('البنك الأهلي المصري **** 5566'), findsOneWidget);
    expect(find.text('إضافة حساب بنكي جديد'), findsOneWidget);
  });

  testWidgets('WalletTransferConfirmScreen renders the amount and destination review cards', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletTransferConfirmScreen(
        amount: 500,
        destinationAccountId: 'bank_nbe_5566',
      ),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('تفاصيل المبلغ'), findsOneWidget);
    expect(find.text('500 ج.م'), findsOneWidget);
    expect(find.text('الحساب المحول إليه'), findsOneWidget);
    expect(find.text('البنك الأهلي المصري **** 5566'), findsOneWidget);
    expect(find.text('تأكيد التحويل'), findsOneWidget);
  });
}
