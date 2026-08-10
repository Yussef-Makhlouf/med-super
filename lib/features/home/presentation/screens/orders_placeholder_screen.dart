import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/widgets/empty_state.dart';

class OrdersPlaceholderScreen extends StatelessWidget {
  const OrdersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('orders.title'.tr()),
        ),
        body: EmptyState(
          title: 'orders.empty'.tr(),
          subtitle: 'common.coming_soon'.tr(),
          icon: Icons.shopping_bag_outlined,
        ),
      );
}
