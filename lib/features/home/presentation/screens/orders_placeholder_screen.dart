import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_list_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_order_status_pill.dart';

// ─── lab mock model (unchanged — lab_booking is BLOCKED, see its STATUS.md;
// this tab stays exactly the placeholder it always was) ────────────────────

enum _LabOrderStatus { processing, onTheWay, completed }

class _LabOrder {
  const _LabOrder({
    required this.id,
    required this.status,
    required this.vendorName,
    required this.summary,
    required this.time,
    required this.total,
  });

  final String id;
  final _LabOrderStatus status;
  final String vendorName;
  final String summary;
  final String time;
  final double total;
}

const _mockLabOrders = [
  _LabOrder(
    id: '100242',
    status: _LabOrderStatus.onTheWay,
    vendorName: 'مختبرات الدقة',
    summary: '2x تحليل دم شامل، خدمة سحب منزلي',
    time: 'اليوم، 09:15 صباحاً',
    total: 850,
  ),
];

// ─── screen: two top tabs — الصيدلية (default, real data) / المعمل (mock) ──

/// The "طلبات" bottom-nav tab. Pharmacy orders are real
/// (`GET /v1/pharmacy-orders`); lab orders stay mock — `lab_booking` is
/// `BLOCKED` (see its own `STATUS.md`), so there is nothing real to wire
/// this tab to yet. Reuses this screen's original header/search-bar/card
/// visual style (restored 2026-09-01 after being briefly deleted when the
/// pharmacy tab took over this route entirely — the two-vendor-tab split
/// is what actually replaces that, not losing the design).
class PatientOrdersScreen extends ConsumerStatefulWidget {
  const PatientOrdersScreen({super.key});

  @override
  ConsumerState<PatientOrdersScreen> createState() =>
      _PatientOrdersScreenState();
}

class _PatientOrdersScreenState extends ConsumerState<PatientOrdersScreen> {
  static const _pageBg = Color(0xFFF3F6FB);
  static const _muted = Color(0xFF8A94A6);

  int _selectedVendorTab = 0; // 0 = pharmacy (default), 1 = lab
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

  List<_LabOrder> get _visibleLabOrders => _mockLabOrders
      .where((o) => _query.isEmpty || o.id.contains(_query))
      .toList();

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
              child: _VendorTabRow(
                selectedTab: _selectedVendorTab,
                onTabChanged: (t) => setState(() => _selectedVendorTab = t),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedVendorTab == 0
                  ? _PharmacyOrdersTab(query: _query)
                  : _visibleLabOrders.isEmpty
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
                      itemCount: _visibleLabOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _LabOrderCard(order: _visibleLabOrders[i]),
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
        GestureDetector(
          onTap: () => context.go('/patient/profile'),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFDCE8FF),
            child: Icon(Icons.person, color: brandBlue),
          ),
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
          onPressed: () => context.go('/patient/notifications'),
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

// ─── vendor tabs (الصيدلية / المعمل) ────────────────────────────────────────

class _VendorTabRow extends StatelessWidget {
  const _VendorTabRow({required this.selectedTab, required this.onTabChanged});

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
            label: 'orders.tab_pharmacy'.tr(),
            isActive: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabButton(
            label: 'orders.tab_lab'.tr(),
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

// ─── pharmacy tab (real data, GET /v1/pharmacy-orders) ─────────────────────

class _PharmacyOrdersTab extends ConsumerWidget {
  const _PharmacyOrdersTab({required this.query});

  final String query;

  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pharmacyOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'errors.unexpected'.tr(),
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(pharmacyOrdersProvider),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
      data: (orders) {
        final visible = orders
            .where(
              (o) =>
                  query.isEmpty ||
                  shortOrderId(o.id).toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        if (visible.isEmpty) {
          return Center(
            child: Text(
              'orders.empty'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: _muted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _PharmacyOrderCard(order: visible[i]),
        );
      },
    );
  }
}

class _PharmacyOrderCard extends StatelessWidget {
  const _PharmacyOrderCard({required this.order});

  final PharmacyOrderDetail order;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('d MMM y, h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quote = order.quote;

    // A `Container` border instead of the mock design's original
    // `IntrinsicHeight` + `Row`-with-a-colored-strip: this card has more
    // content rows than the mock ever did (fulfillment method + date are
    // real fields the mock never showed), and `IntrinsicHeight`'s dry
    // layout pass under-measured the taller column, overflowing by a
    // consistent 12px. A border avoids that measurement entirely.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            width: 5,
            color: PharmacyOrderStatusPill.colorFor(order.status),
          ),
        ),
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
        child: InkWell(
          onTap: () => context.push('/patient/orders/${order.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Row(
                          children: [
                            PharmacyOrderStatusPill(status: order.status),
                            const Spacer(),
                            Text(
                              '#${shortOrderId(order.id)}',
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
                              child: const Icon(
                                Icons.local_pharmacy_outlined,
                                size: 20,
                                color: brandBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.pharmacyName ??
                              'pharmacy_booking.orders.pharmacy_label'.tr(),
                          style: textTheme.titleSmall?.copyWith(
                            color: brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DeliveryMethod.fromApiValue(
                            order.fulfillmentType,
                          ).titleKey.tr(),
                          style: textTheme.bodySmall?.copyWith(color: _ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: textTheme.bodySmall?.copyWith(color: _muted),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEFF2F7)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  context.push('/patient/orders/${order.id}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brandBlue,
                                side: BorderSide(
                                  color: brandBlue.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('orders.track'.tr()),
                            ),
                            const Spacer(),
                            if (quote != null)
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
                                    '${quote.totalPrice} ${quote.currency}',
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
      ),
    );
  }
}

// ─── lab order card (unchanged mock design) ────────────────────────────────

class _LabOrderCard extends StatelessWidget {
  const _LabOrderCard({required this.order});

  final _LabOrder order;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  Color _statusColor(_LabOrderStatus s) => switch (s) {
    _LabOrderStatus.processing => const Color(0xFFF59E0B),
    _LabOrderStatus.onTheWay => const Color(0xFF0EA5E9),
    _LabOrderStatus.completed => const Color(0xFF22C55E),
  };

  String _statusLabel(_LabOrderStatus s) => switch (s) {
    _LabOrderStatus.processing => 'orders.status_processing'.tr(),
    _LabOrderStatus.onTheWay => 'orders.status_on_the_way'.tr(),
    _LabOrderStatus.completed => 'orders.status_completed'.tr(),
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
                            child: const Icon(
                              Icons.science_outlined,
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
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('orders.details'.tr()),
                          ),
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
