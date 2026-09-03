import 'package:dio/dio.dart';
import '../models/deposit_request_model.dart';
import '../models/refund_request_model.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletRemoteDatasource {
  Future<WalletBalanceModel> getBalance();
  Future<List<WalletTransactionModel>> getTransactions();
  Future<WalletTransactionModel> getTransactionById(String id);
  Future<WalletTransactionModel> depositBalance(DepositRequestModel request);
  Future<WalletTransactionModel> transferBalance({
    required double amount,
    required String destinationAccountId,
  });
  Future<RefundRequestModel> requestRefund({
    required String transactionId,
    required String reason,
    required String details,
  });
  Future<RefundRequestModel> getRefundStatus(String refundId);
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final Dio dio;

  WalletRemoteDatasourceImpl(this.dio);

  @override
  Future<WalletBalanceModel> getBalance() async {
    final response = await dio.get('/v1/wallet/balance');
    final data = _extract(response.data);
    return WalletBalanceModel.fromJson(data);
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions() async {
    final response = await dio.get('/v1/wallet/transactions');
    final raw = response.data;
    List list = [];
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw;
      if (inner is List) {
        list = inner;
      } else if (inner is Map<String, dynamic>) {
        final items = inner['items'];
        if (items is List) list = items;
      }
    } else if (raw is List) {
      list = raw;
    }
    return list
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WalletTransactionModel> getTransactionById(String id) async {
    final response = await dio.get('/v1/wallet/transactions/$id');
    final data = _extract(response.data);
    return WalletTransactionModel.fromJson(data);
  }

  @override
  Future<WalletTransactionModel> depositBalance(DepositRequestModel request) async {
    final response = await dio.post(
      '/v1/wallet/deposits',
      data: {
        'amount': request.amount,
        'payment_method_id': request.paymentMethodId,
      },
    );
    final data = _extract(response.data);
    return WalletTransactionModel.fromJson(data);
  }

  @override
  Future<WalletTransactionModel> transferBalance({
    required double amount,
    required String destinationAccountId,
  }) async {
    final response = await dio.post(
      '/v1/wallet/transfers',
      data: {
        'amount': amount,
        'destination_account_id': destinationAccountId,
      },
    );
    final data = _extract(response.data);
    return WalletTransactionModel.fromJson(data);
  }

  @override
  Future<RefundRequestModel> requestRefund({
    required String transactionId,
    required String reason,
    required String details,
  }) async {
    final response = await dio.post(
      '/v1/wallet/refunds',
      data: {
        'transaction_id': transactionId,
        'reason': reason,
        'details': details,
      },
    );
    final data = _extract(response.data);
    return RefundRequestModel.fromJson(data);
  }

  @override
  Future<RefundRequestModel> getRefundStatus(String refundId) async {
    final response = await dio.get('/v1/wallet/refunds/$refundId');
    final data = _extract(response.data);
    return RefundRequestModel.fromJson(data);
  }

  Map<String, dynamic> _extract(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }
}
