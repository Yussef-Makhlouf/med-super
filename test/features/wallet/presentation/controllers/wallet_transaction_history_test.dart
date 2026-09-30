import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:med_super/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:med_super/features/wallet/presentation/controllers/wallet_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

WalletTransaction _transaction(String id) => WalletTransaction(
  id: id,
  type: TransactionType.deposit,
  amount: 125,
  createdAt: DateTime.utc(2026, 9, 24),
  status: TransactionStatus.completed,
);

void main() {
  late _MockWalletRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockWalletRepository();
    container = ProviderContainer(
      overrides: [walletRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test(
    'keeps the ledger and retries a failed page without duplicates',
    () async {
      var nextPageAttempts = 0;
      when(
        () => repository.getTransactions(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final cursor = invocation.namedArguments[#cursor] as String?;
        if (cursor == null) {
          return WalletTransactionPage(
            items: [_transaction('one')],
            nextCursor: 'page-2',
          );
        }
        nextPageAttempts++;
        if (nextPageAttempts == 1) throw StateError('Temporary failure');
        return WalletTransactionPage(
          items: [_transaction('one'), _transaction('two')],
          nextCursor: null,
        );
      });

      await container.read(walletTransactionHistoryProvider.future);
      final controller = container.read(
        walletTransactionHistoryProvider.notifier,
      );
      await controller.loadMore();

      var history = container
          .read(walletTransactionHistoryProvider)
          .requireValue;
      expect(history.items.map((item) => item.id), ['one']);
      expect(history.nextCursor, 'page-2');
      expect(history.loadMoreFailed, isTrue);

      await controller.loadMore();
      history = container.read(walletTransactionHistoryProvider).requireValue;
      expect(history.items.map((item) => item.id), ['one', 'two']);
      expect(history.hasMore, isFalse);
      expect(history.loadMoreFailed, isFalse);
    },
  );

  test('stops when the ledger repeats the active cursor', () async {
    when(
      () => repository.getTransactions(
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      return WalletTransactionPage(
        items: [_transaction(cursor ?? 'one')],
        nextCursor: 'page-2',
      );
    });

    await container.read(walletTransactionHistoryProvider.future);
    await container.read(walletTransactionHistoryProvider.notifier).loadMore();

    final history = container
        .read(walletTransactionHistoryProvider)
        .requireValue;
    expect(history.items.map((item) => item.id), ['one', 'page-2']);
    expect(history.hasMore, isFalse);
  });

  test('resolves a transaction from later ledger pages', () async {
    when(
      () => repository.getTransactions(
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      return cursor == null
          ? WalletTransactionPage(
              items: [_transaction('one')],
              nextCursor: 'page-2',
            )
          : WalletTransactionPage(
              items: [_transaction('two')],
              nextCursor: null,
            );
    });

    final transaction = await container.read(
      walletTransactionDetailProvider('two').future,
    );

    expect(transaction.id, 'two');
  });
}
