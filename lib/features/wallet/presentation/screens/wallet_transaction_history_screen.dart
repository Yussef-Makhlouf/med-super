import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import '../controllers/wallet_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'wallet_transaction_detail_screen.dart';

class WalletTransactionHistoryScreen extends ConsumerWidget {
  const WalletTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(walletTransactionHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.transaction_history'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.ink900,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: historyAsync.when(
        data: (history) => RefreshIndicator(
          onRefresh: () =>
              ref.read(walletTransactionHistoryProvider.notifier).refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: history.items.isEmpty
                ? (history.hasMore ? 2 : 1)
                : history.items.length + (history.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= history.items.length && history.hasMore) {
                if (history.isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (history.loadMoreFailed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'wallet.load_more_failed'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.mutedText2),
                          ),
                        ),
                      TextButton(
                        onPressed: () => ref
                            .read(walletTransactionHistoryProvider.notifier)
                            .loadMore(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          history.loadMoreFailed
                              ? 'common.retry'.tr()
                              : 'wallet.load_more'.tr(),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (history.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      'wallet.no_transactions'.tr(),
                      style: const TextStyle(color: AppColors.mutedText2),
                    ),
                  ),
                );
              }

              final tx = history.items[index];
              return WalletTransactionListTile(
                transaction: tx,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          WalletTransactionDetailScreen(transactionId: tx.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('common.error'.tr()),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref
                    .read(walletTransactionHistoryProvider.notifier)
                    .refresh(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
