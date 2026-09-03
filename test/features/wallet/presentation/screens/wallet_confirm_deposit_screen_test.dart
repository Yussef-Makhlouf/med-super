import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_confirm_deposit_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletConfirmDepositScreen renders the amount and payment method review cards', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletConfirmDepositScreen(
        amount: 500,
        paymentMethodId: 'card_visa_4242',
      ),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('تفاصيل المبلغ'), findsOneWidget);
    expect(find.text('500 ج.م'), findsOneWidget);
    expect(find.text('طريقة الدفع المختارة'), findsOneWidget);
    expect(find.text('Visa **** 4242'), findsOneWidget);
    expect(find.text('تعديل'), findsNWidgets(2));
    expect(find.text('تأكيد والدفع'), findsOneWidget);
  });
}
