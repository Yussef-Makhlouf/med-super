import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRemoteDatasourceProvider = Provider<WalletRemoteDatasource>((ref) {
  return WalletRemoteDatasourceImpl(ref.watch(dioProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDatasourceProvider));
});

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  return ref.watch(walletRepositoryProvider).getWalletBalance();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  return ref.watch(walletRepositoryProvider).getTransactions();
});

final walletTransactionDetailProvider =
    FutureProvider.family<WalletTransaction, String>((ref, id) async {
  return ref.watch(walletRepositoryProvider).getTransactionDetail(id);
});

final refundStatusProvider =
    FutureProvider.family<RefundRequest, String>((ref, id) async {
  return ref.watch(walletRepositoryProvider).getRefundStatus(id);
});
