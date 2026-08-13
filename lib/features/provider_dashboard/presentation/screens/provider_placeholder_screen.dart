import 'package:flutter/material.dart';
import 'package:med_super/core/widgets/empty_state.dart';

class ProviderPlaceholderScreen extends StatelessWidget {
  const ProviderPlaceholderScreen({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: EmptyState(
          title: title,
          subtitle: 'هذه الميزة قيد التطوير وستكون متاحة قريبًا.',
          icon: Icons.construction_rounded,
        ),
      ),
    );
  }
}
