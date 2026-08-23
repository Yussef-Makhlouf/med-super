import '../../domain/entities/deposit_request.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/entities/transfer_request.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/deposit_request_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource remoteDatasource;

  WalletRepositoryImpl(this.remoteDatasource);

  @override
  Future<WalletBalance> getWalletBalance() => remoteDatasource.getBalance();

  @override
  Future<List<WalletTransaction>> getTransactions() =>
      remoteDatasource.getTransactions();

  @override
  Future<WalletTransaction> getTransactionDetail(String id) =>
      remoteDatasource.getTransactionById(id);

  @override
  Future<WalletTransaction> depositBalance(DepositRequest request) {
    return remoteDatasource.depositBalance(DepositRequestModel(
      amount: request.amount,
      paymentMethodId: request.paymentMethodId,
    ));
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
