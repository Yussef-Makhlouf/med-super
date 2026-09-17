import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_refund_request_screen.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_refund_status_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletRefundRequestScreen renders refund form options', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletRefundRequestScreen(transactionId: 'tx-101'),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('طلب استرداد'), findsAtLeastNWidgets(1));
    expect(find.text('سبب طلب الاسترداد'), findsOneWidget);
    expect(find.text('إلغاء الموعد قبل 24 ساعة'), findsOneWidget);
    expect(find.text('إرسال طلب الاسترداد'), findsOneWidget);
  });

  testWidgets('WalletRefundStatusScreen renders timeline tracking', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      const WalletRefundStatusScreen(refundId: 'ref-201'),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('حالة طلب الاسترداد'), findsAtLeastNWidgets(1));
    expect(find.text('تم إرسال الطلب'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.text('مسار الطلب'), findsOneWidget);
    expect(find.text('العودة للمحفظة'), findsOneWidget);
  });
}
