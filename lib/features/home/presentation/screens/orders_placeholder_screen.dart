import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

// ─── model ────────────────────────────────────────────────────────────────────

enum _OrderStatus { processing, onTheWay, completed }

enum _VendorType { pharmacy, lab }

class _Order {
  const _Order({
    required this.id,
    required this.status,
    required this.vendorName,
    required this.vendorType,
    required this.summary,
    required this.time,
    required this.total,
  });

  final String id;
  final _OrderStatus status;
  final String vendorName;
  final _VendorType vendorType;
  final String summary;
  final String time;
  final double total;
}

const _mockOrders = [
  _Order(
    id: '100245',
    status: _OrderStatus.processing,
    vendorName: 'صيدلية الرعاية',
    vendorType: _VendorType.pharmacy,
    summary: '13x أدوية وصفة طبية, 4x فيتامينات',
    time: 'اليوم، 10:30 صباحاً',
    total: 350,
  ),
  _Order(
    id: '100242',
    status: _OrderStatus.onTheWay,
    vendorName: 'مختبرات الدقة',
    vendorType: _VendorType.lab,
    summary: '2x تحليل دم شامل، خدمة سحب منزلي',
    time: 'اليوم، 09:15 صباحاً',
    total: 850,
  ),
  _Order(
    id: '100180',
    status: _OrderStatus.completed,
    vendorName: 'صيدلية الشفاء',
    vendorType: _VendorType.pharmacy,
    summary: '21x مسكن ألم, 4x مستلزمات طبية',
    time: 'أمس، 02:45 مساءً',
    total: 120,
  ),
];

// ─── screen ───────────────────────────────────────────────────────────────────

class PatientOrdersScreen extends ConsumerStatefulWidget {
  const PatientOrdersScreen({super.key});

  @override
  ConsumerState<PatientOrdersScreen> createState() =>
      _PatientOrdersScreenState();
}

class _PatientOrdersScreenState extends ConsumerState<PatientOrdersScreen> {
  static const _pageBg = Color(0xFFF3F6FB);
  static const _muted = Color(0xFF8A94A6);

  int _selectedTab = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Order> get _visibleOrders {
    const currentGroup = {_OrderStatus.processing, _OrderStatus.onTheWay};
    const previousGroup = {_OrderStatus.completed};
    final group = _selectedTab == 0 ? currentGroup : previousGroup;
    return _mockOrders
        .where((o) => group.contains(o.status))
        .where((o) => _query.isEmpty || o.id.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'أحمد محمد';

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _OrdersHeader(displayName: displayName),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OrderSearchBar(controller: _searchController),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TabRow(
                selectedTab: _selectedTab,
                onTabChanged: (t) => setState(() => _selectedTab = t),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _visibleOrders.isEmpty
                  ? Center(
                      child: Text(
                        'orders.empty'.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: _muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: _visibleOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _OrderCard(order: _visibleOrders[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header ───────────────────────────────────────────────────────────────────

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.displayName});

  final String displayName;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFDCE8FF),
          child: Icon(Icons.person, color: brandBlue),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'home.welcome'.tr(),
              style: textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            Text(
              displayName,
              style: textTheme.titleMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: _ink),
        ),
        IconButton(
          onPressed: () {},
          icon: const Badge(
            smallSize: 8,
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_outlined, color: _ink),
          ),
        ),
      ],
    );
  }
}

// ─── search bar ───────────────────────────────────────────────────────────────

class _OrderSearchBar extends StatelessWidget {
  const _OrderSearchBar({required this.controller});

  final TextEditingController controller;

  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'orders.search_hint'.tr(),
        hintStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(Icons.search, color: _muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
      ),
    );
  }
}

// ─── tabs ─────────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow({required this.selectedTab, required this.onTabChanged});

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'orders.tab_current'.tr(),
            isActive: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabButton(
            label: 'orders.tab_previous'.tr(),
            isActive: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: brandBlue.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _Order order;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  Color _statusColor(_OrderStatus s) => switch (s) {
    _OrderStatus.processing => const Color(0xFFF59E0B),
    _OrderStatus.onTheWay => const Color(0xFF0EA5E9),
    _OrderStatus.completed => const Color(0xFF22C55E),
  };

  String _statusLabel(_OrderStatus s) => switch (s) {
    _OrderStatus.processing => 'orders.status_processing'.tr(),
    _OrderStatus.onTheWay => 'orders.status_on_the_way'.tr(),
    _OrderStatus.completed => 'orders.status_completed'.tr(),
  };

  IconData _vendorIcon(_VendorType t) => switch (t) {
    _VendorType.pharmacy => Icons.local_pharmacy_outlined,
    _VendorType.lab => Icons.science_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusPill(
                            label: _statusLabel(order.status),
                            color: statusColor,
                          ),
                          const Spacer(),
                          Text(
                            '#${order.id}',
                            style: textTheme.bodySmall?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _vendorIcon(order.vendorType),
                              size: 20,
                              color: brandBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.vendorName,
                        style: textTheme.titleSmall?.copyWith(
                          color: brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.summary,
                        style: textTheme.bodySmall?.copyWith(color: _ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.time,
                        style: textTheme.bodySmall?.copyWith(color: _muted),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFEFF2F7)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _CardCta(status: order.status),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'orders.total'.tr(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: _muted,
                                ),
                              ),
                              Text(
                                '${order.total.toStringAsFixed(0)} ${'orders.currency'.tr()}',
                                style: textTheme.titleSmall?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardCta extends StatelessWidget {
  const _CardCta({required this.status});

  final _OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _OrderStatus.processing => FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.local_shipping_outlined, size: 16),
        label: Text('orders.track'.tr()),
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      _OrderStatus.onTheWay => OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6B7280),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text('orders.details'.tr()),
      ),
      _OrderStatus.completed => OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.refresh, size: 16),
        label: Text('orders.reorder'.tr()),
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          side: BorderSide(color: brandBlue.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    };
  }
}
