import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';

class WalletLinkedCardsScreen extends StatelessWidget {
  const WalletLinkedCardsScreen({super.key});

  static const _cards = [
    (
      title: 'Mastercard **** 8888',
      subtitle: 'تنتهي في 12/28',
      icon: Icons.credit_card,
      iconColor: Color(0xFFEA580C),
      isDefault: true,
    ),
    (
      title: 'Visa **** 4242',
      subtitle: 'تنتهي في 09/27',
      icon: Icons.credit_card,
      iconColor: brandBlue,
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.linked_cards'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _cards.length,
                separatorBuilder: (_, _1) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: card.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(card.icon, color: card.iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (card.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'wallet.default_card'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: brandBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppButton.outlined(
              label: 'wallet.add_new_card'.tr(),
              icon: const Icon(Icons.add, size: 18),
              fullWidth: true,
              borderRadius: 16,
              foregroundColor: brandBlue,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('wallet.add_card_coming_soon'.tr())),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
