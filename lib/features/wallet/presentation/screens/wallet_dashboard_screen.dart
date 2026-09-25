import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/theme/app_palette.dart';
import '../controllers/wallet_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/transaction_list_tile.dart';
import 'wallet_add_balance_screen.dart';
// import 'wallet_linked_cards_screen.dart'; // Unused while "بطاقات مرتبطة" is commented out below.
import 'wallet_pay_bills_screen.dart';
import 'wallet_transaction_detail_screen.dart';
import 'wallet_transaction_history_screen.dart';

// import 'wallet_transfer_screen.dart'; // Unused while "تحويل" is commented out below.

class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  static const routeName = '/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);
    final isMock = ref.watch(appConfigProvider).isMock;

    return Scaffold(
      backgroundColor: AppPalette.paper,
      appBar: AppBar(
        backgroundColor: AppPalette.paper,
        elevation: 0,
        leading: IconButton(
          tooltip: 'common.back'.tr(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppPalette.ink,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
          ref.invalidate(walletTransactionHistoryProvider);
          ref.invalidate(walletTransactionDetailProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'wallet.title'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'wallet.dashboard_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              balanceAsync.when(
                data: (balance) => WalletBalanceCard(
                  balance: balance,
                  onAddBalance: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WalletAddBalanceScreen(),
                      ),
                    );
                  },
                  // "تحويل" isn't part of the real flow yet — see the
                  // matching comment in `WalletBalanceCard` above the
                  // commented-out button that used to call this.
                  // onTransfer: () {
                  //   Navigator.of(context).push(
                  //     MaterialPageRoute(
                  //       builder: (_) => const WalletTransferScreen(),
                  //     ),
                  //   );
                  // },
                ),
                loading: () => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Container(
                  height: 180,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(child: Text('common.error'.tr())),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // "بطاقات مرتبطة" isn't part of the real flow yet — no
                  // linked-card management exists on the backend, it only
                  // ever read from `WalletLinkedCardsScreen`'s own mock
                  // data. Commented out rather than deleted: the screen and
                  // route stay in place for when that flow is actually
                  // built.
                  // Expanded(
                  //   child: WalletQuickActionTile(
                  //     icon: Icons.credit_card,
                  //     iconBg: const Color(0xFFFDECE4),
                  //     iconColor: const Color(0xFFC2410C),
                  //     title: 'wallet.linked_cards'.tr(),
                  //     onTap: () {
                  //       Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //           builder: (_) => const WalletLinkedCardsScreen(),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  // const SizedBox(width: 10),
                  Expanded(
                    child: WalletQuickActionTile(
                      icon: Icons.history,
                      iconBg: AppPalette.successSoft,
                      iconColor: AppPalette.success,
                      title: 'wallet.transaction_history'.tr(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const WalletTransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isMock) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: WalletQuickActionTile(
                        icon: Icons.event_note_outlined,
                        iconBg: AppPalette.primarySoft,
                        iconColor: AppPalette.primary,
                        title: 'wallet.pay_bills'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WalletPayBillsScreen(),
                            ),
                          ),
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'wallet.recent_transactions'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppPalette.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const WalletTransactionHistoryScreen(),
                        ),
                      );
                    },
                    child: Text('wallet.view_all'.tr()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'wallet.no_transactions'.tr(),
                          style: const TextStyle(color: AppPalette.inkMuted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _1) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return WalletTransactionListTile(
                        transaction: tx,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WalletTransactionDetailScreen(
                                transactionId: tx.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('common.error'.tr())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
