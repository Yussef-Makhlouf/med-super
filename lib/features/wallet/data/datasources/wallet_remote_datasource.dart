import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/features/wallet/domain/entities/wallet_transaction.dart';
import '../models/refund_request_model.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_top_up_initiation_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletRemoteDatasource {
  Future<WalletBalanceModel> getBalance();
  Future<WalletTransactionPage> getTransactions({String? cursor, int? limit});
  Future<WalletTopUpInitiationModel> initiateTopUp({
    required String amount,
    required PaymentCustomerInfo customer,
  });
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

/// The two reads plus `initiateTopUp` below are the real File 12 Part 50.3
/// wallet contract. The transfer/refund writes underneath them are
/// mock-only — no such endpoint exists on the backend (see `STATUS.md`).
class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final Dio dio;

  WalletRemoteDatasourceImpl(this.dio);

  @override
  Future<WalletBalanceModel> getBalance() async {
    final response = await dio.get(ApiPaths.wallet);
    return WalletBalanceModel.fromJson(_extract(response.data));
  }

  @override
  Future<WalletTransactionPage> getTransactions({
    String? cursor,
    int? limit,
  }) async {
    final response = await dio.get(
      ApiPaths.walletTransactions,
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
    );
    final data = _extract(response.data);
    final items = (data['transactions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WalletTransactionModel.fromJson)
        .toList();
    return WalletTransactionPage(
      items: items,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  /// Card-only by contract — the backend hardcodes `method: 'CARD'`, so
  /// there is no payment-method parameter to pass. `amount` is a fixed
  /// 2-decimal string (`@IsDecimal`), never a number.
  @override
  Future<WalletTopUpInitiationModel> initiateTopUp({
    required String amount,
    required PaymentCustomerInfo customer,
  }) async {
    final response = await dio.post(
      ApiPaths.walletTopUp,
      data: {'amount': amount, 'customer': customer.toJson()},
    );
    return WalletTopUpInitiationModel.fromJson(_extract(response.data));
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
