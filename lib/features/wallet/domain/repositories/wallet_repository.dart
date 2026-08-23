import '../entities/deposit_request.dart';
import '../entities/refund_request.dart';
import '../entities/transfer_request.dart';
import '../entities/wallet_balance.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<WalletBalance> getWalletBalance();
  Future<List<WalletTransaction>> getTransactions();
  Future<WalletTransaction> getTransactionDetail(String id);
  Future<WalletTransaction> depositBalance(DepositRequest request);
  Future<WalletTransaction> transferBalance(TransferRequest request);
  Future<RefundRequest> requestRefund({
    required String transactionId,
    required String reason,
    String? details,
  });
  Future<RefundRequest> getRefundStatus(String refundId);
}
