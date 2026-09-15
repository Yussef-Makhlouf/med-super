import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import '../entities/refund_request.dart';
import '../entities/transfer_request.dart';
import '../entities/wallet_balance.dart';
import '../entities/wallet_top_up_initiation.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<WalletBalance> getWalletBalance();
  Future<WalletTransactionPage> getTransactions({String? cursor, int? limit});
  Future<WalletTopUpInitiation> initiateTopUp({
    required double amount,
    required PaymentCustomerInfo customer,
  });
  Future<WalletTransaction> transferBalance(TransferRequest request);
  Future<RefundRequest> requestRefund({
    required String transactionId,
    required String reason,
    String? details,
  });
  Future<RefundRequest> getRefundStatus(String refundId);
}
