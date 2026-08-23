import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import '../controllers/wallet_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/transaction_list_tile.dart';
import 'wallet_add_balance_screen.dart';
import 'wallet_linked_cards_screen.dart';
import 'wallet_pay_bills_screen.dart';
import 'wallet_transaction_detail_screen.dart';
import 'wallet_transaction_history_screen.dart';
import 'wallet_transfer_screen.dart';

class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  static const routeName = '/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);


    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
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
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'wallet.dashboard_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText2,
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
                  onTransfer: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WalletTransferScreen(),
                      ),
                    );
                  },
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
                  child: Center(
                    child: Text('common.error'.tr()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: WalletQuickActionTile(
                      icon: Icons.credit_card,
                      iconBg: const Color(0xFFFDECE4),
                      iconColor: const Color(0xFFC2410C),
                      title: 'wallet.linked_cards'.tr(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WalletLinkedCardsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WalletQuickActionTile(
                      icon: Icons.history,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'wallet.transaction_history'.tr(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WalletTransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WalletQuickActionTile(
                      icon: Icons.event_note_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: brandBlue,
                      title: 'wallet.pay_bills'.tr(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WalletPayBillsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
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
                      color: AppColors.ink900,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WalletTransactionHistoryScreen(),
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
                          style: const TextStyle(color: AppColors.mutedText2),
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
                error: (err, _) => Center(
                  child: Text('common.error'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
