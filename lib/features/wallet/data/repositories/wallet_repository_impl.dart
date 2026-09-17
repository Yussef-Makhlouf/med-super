import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/entities/transfer_request.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_top_up_initiation.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource remoteDatasource;

  WalletRepositoryImpl(this.remoteDatasource);

  @override
  Future<WalletBalance> getWalletBalance() => remoteDatasource.getBalance();

  @override
  Future<WalletTransactionPage> getTransactions({String? cursor, int? limit}) =>
      remoteDatasource.getTransactions(cursor: cursor, limit: limit);

  /// The backend takes the amount as a fixed 2-decimal string
  /// (`TopUpWalletDto.@IsDecimal`), so the conversion happens here rather
  /// than leaking a formatting concern into the screens.
  @override
  Future<WalletTopUpInitiation> initiateTopUp({
    required double amount,
    required PaymentCustomerInfo customer,
  }) {
    return remoteDatasource.initiateTopUp(
      amount: amount.toStringAsFixed(2),
      customer: customer,
    );
  }

  @override
  Future<WalletTransaction> transferBalance(TransferRequest request) {
    return remoteDatasource.transferBalance(
      amount: request.amount,
      destinationAccountId: request.destinationAccountId,
    );
  }

  @override
  Future<RefundRequest> requestRefund({
    required String transactionId,
    required String reason,
    String? details,
  }) {
    return remoteDatasource.requestRefund(
      transactionId: transactionId,
      reason: reason,
      details: details ?? '',
    );
  }

  @override
  Future<RefundRequest> getRefundStatus(String refundId) =>
      remoteDatasource.getRefundStatus(refundId);
}
