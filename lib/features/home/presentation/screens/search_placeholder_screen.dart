import 'package:flutter/material.dart';
import 'package:med_super/core/widgets/empty_state.dart';

class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Search')),
    body: const EmptyState(
      title: 'Search doctors & clinics',
      subtitle: 'Sprint 2 — provider directory',
      icon: Icons.search,
    ),
  );
}
