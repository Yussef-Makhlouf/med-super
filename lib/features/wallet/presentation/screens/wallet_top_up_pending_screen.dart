// `easy_localization` re-exports `intl`, whose `TextDirection` shadows the
// `dart:ui` enum this file needs for the LTR checkout URL.
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/wallet_top_up_initiation.dart';

/// Terminal screen of the top-up flow.
///
/// Deliberately **not** a success screen: `POST /v1/wallet/top-up` creates a
/// `PENDING` ledger row and nothing more — the balance moves only when
/// Paymob's capture webhook reaches the backend. Claiming "تمت الإضافة"
/// here would be a lie the ledger contradicts.
///
/// The checkout URL opens automatically in the device's browser (no
/// in-app WebView dependency needed for that — `url_launcher` just hands
/// the URL to the OS). The link stays on screen with a copy fallback in
/// case the automatic launch is blocked or the user wants to send it to
/// another device.
class WalletTopUpPendingScreen extends StatefulWidget {
  const WalletTopUpPendingScreen({
    required this.initiation,
    required this.amount,
    super.key,
  });

  final WalletTopUpInitiation initiation;
  final double amount;

  @override
  State<WalletTopUpPendingScreen> createState() =>
      _WalletTopUpPendingScreenState();
}

class _WalletTopUpPendingScreenState extends State<WalletTopUpPendingScreen> {
  bool _launchFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckout());
  }

  Future<void> _openCheckout() async {
    final uri = Uri.tryParse(widget.initiation.redirectUrl);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) setState(() => _launchFailed = true);
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: widget.initiation.redirectUrl),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('wallet.checkout_link_copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFD97706),
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'wallet.top_up_pending_title'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.ink900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                (_launchFailed
                        ? 'wallet.top_up_pending_sub_manual'
                        : 'wallet.top_up_pending_sub')
                    .tr(namedArgs: {'amount': widget.amount.toStringAsFixed(2)}),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.mutedText2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'wallet.checkout_link_label'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.initiation.redirectUrl,
                      textDirection: ui.TextDirection.ltr,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            label: 'wallet.open_checkout_link'.tr(),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            borderRadius: 12,
                            onPressed: _openCheckout,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.outlined(
                            label: 'wallet.copy_checkout_link'.tr(),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            borderRadius: 12,
                            onPressed: () => _copyLink(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton.filled(
                label: 'wallet.return_to_wallet'.tr(),
                fullWidth: true,
                borderRadius: 16,
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                onPressed: () => context.go('/patient/home/wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
