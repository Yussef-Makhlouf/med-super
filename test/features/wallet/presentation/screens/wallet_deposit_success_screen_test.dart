import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_deposit_success_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('WalletDepositSuccessScreen renders deposit receipt summary', (tester) async {
    final transaction = WalletTransaction(
      id: 'tx-900',
      title: 'شحن المحفظة',
      type: TransactionType.deposit,
      amount: 500,
      timestamp: DateTime(2023, 10, 24, 10, 30),
      status: TransactionStatus.completed,
      referenceNumber: 'TRX-8291034',
      paymentMethod: 'Visa **** 4242',
    );

    await pumpLocalizedWidget(
      tester,
      WalletDepositSuccessScreen(transaction: transaction),
    );

    await tester.pump();

    expect(find.text('500 ج.م'), findsOneWidget);
    expect(find.text('#TRX-8291034'), findsOneWidget);
    expect(find.text('Visa **** 4242'), findsOneWidget);
  });
}
