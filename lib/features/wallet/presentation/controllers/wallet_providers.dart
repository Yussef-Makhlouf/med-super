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

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  final page = await ref.watch(walletRepositoryProvider).getTransactions();
  return page.items;
});

class WalletTransactionHistoryState {
  const WalletTransactionHistoryState({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<WalletTransaction> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  WalletTransactionHistoryState copyWith({
    List<WalletTransaction>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => WalletTransactionHistoryState(
    items: items ?? this.items,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

class WalletTransactionHistoryController
    extends AsyncNotifier<WalletTransactionHistoryState> {
  final Set<String> _visitedCursors = {};

  @override
  Future<WalletTransactionHistoryState> build() async {
    _visitedCursors.clear();
    final page = await ref.watch(walletRepositoryProvider).getTransactions();
    return WalletTransactionHistoryState(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(walletRepositoryProvider)
          .getTransactions(cursor: current.nextCursor);
      final requestedCursor = current.nextCursor;
      if (requestedCursor != null) _visitedCursors.add(requestedCursor);
      final seenIds = current.items.map((item) => item.id).toSet();
      final newItems = page.items
          .where((item) => seenIds.add(item.id))
          .toList(growable: false);
      final nextCursor =
          page.nextCursor != null && _visitedCursors.contains(page.nextCursor)
          ? null
          : page.nextCursor;
      state = AsyncData(
        WalletTransactionHistoryState(
          items: [...current.items, ...newItems],
          nextCursor: nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The provider keeps the error for the screen's retry state.
    }
  }
}

final walletTransactionHistoryProvider =
    AsyncNotifierProvider<
      WalletTransactionHistoryController,
      WalletTransactionHistoryState
    >(WalletTransactionHistoryController.new);

/// The backend ships no per-transaction route — `GET /v1/wallet/transactions`
/// is the whole ledger read (File 12 Part 50.3) — so the detail screen
/// resolves its transaction by walking those cursor pages rather than calling
/// an endpoint that doesn't exist.
final walletTransactionDetailProvider =
    FutureProvider.family<WalletTransaction, String>((ref, id) async {
      final repository = ref.watch(walletRepositoryProvider);
      String? cursor;
      final seenCursors = <String>{};

      while (true) {
        final page = await repository.getTransactions(cursor: cursor);
        for (final transaction in page.items) {
          if (transaction.id == id) return transaction;
        }

        final nextCursor = page.nextCursor;
        if (nextCursor == null || !seenCursors.add(nextCursor)) {
          throw StateError('Wallet transaction not found in available pages');
        }
        cursor = nextCursor;
      }
    });

final refundStatusProvider = FutureProvider.family<RefundRequest, String>((
  ref,
  id,
) async {
  return ref.watch(walletRepositoryProvider).getRefundStatus(id);
});
