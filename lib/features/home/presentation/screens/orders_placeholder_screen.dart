import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_list_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_order_status_pill.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_list_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_order_status_pill.dart';

// ─── screen: two top tabs — الصيدلية / المعمل, both real data ──────────────

/// The "طلبات" bottom-nav tab. Pharmacy orders (`GET /v1/pharmacy-orders`)
/// and lab orders (`GET /v1/lab-orders`, un-blocked 2026-09-05 — this tab
/// used to show a hardcoded mock list, see `lab_booking/STATUS.md`) are both
/// real now. Reuses this screen's original header/search-bar/card visual
/// style (restored 2026-09-01 after being briefly deleted when the pharmacy
/// tab took over this route entirely — the two-vendor-tab split is what
/// actually replaces that, not losing the design).
class PatientOrdersScreen extends ConsumerStatefulWidget {
  const PatientOrdersScreen({super.key});

  @override
  ConsumerState<PatientOrdersScreen> createState() =>
      _PatientOrdersScreenState();
}

class _PatientOrdersScreenState extends ConsumerState<PatientOrdersScreen> {
  static const _pageBg = Color(0xFFF3F6FB);

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
                  : _LabOrdersTab(query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header ───────────────────────────────────────────────────────────────────

class _OrdersHeader extends ConsumerWidget {
  const _OrdersHeader({required this.displayName});

  final String displayName;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;
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
          icon: Badge(
            smallSize: 8,
            backgroundColor: Colors.red,
            isLabelVisible: hasUnread,
            child: const Icon(Icons.notifications_outlined, color: _ink),
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
                  shortOrderId(
                    o.id,
                  ).toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        if (visible.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(pharmacyOrdersProvider.future),
            child: ListView(
              // A `Center`'s child alone can't be pulled — a scrollable
              // child (even an empty-looking one) is required for
              // `RefreshIndicator` to receive the drag gesture at all.
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      'orders.empty'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: _muted),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(pharmacyOrdersProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PharmacyOrderCard(order: visible[i]),
          ),
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
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            style: textTheme.bodySmall?.copyWith(color: _muted),
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

// ─── lab tab (real data, GET /v1/lab-orders) ───────────────────────────────

class _LabOrdersTab extends ConsumerWidget {
  const _LabOrdersTab({required this.query});

  final String query;

  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(labOrdersProvider);

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
              onPressed: () => ref.invalidate(labOrdersProvider),
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
                  shortOrderId(o.id).toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        if (visible.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(labOrdersProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      'orders.empty'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: _muted),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(labOrdersProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _LabOrderCard(order: visible[i]),
          ),
        );
      },
    );
  }
}

class _LabOrderCard extends StatelessWidget {
  const _LabOrderCard({required this.order});

  final LabOrderDetail order;

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            width: 5,
            color: LabOrderStatusPill.colorFor(order.status),
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
          onTap: () => context.push('/patient/orders/lab/${order.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LabOrderStatusPill(status: order.status),
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
                        Icons.biotech_outlined,
                        size: 20,
                        color: brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                          context.push('/patient/orders/lab/${order.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandBlue,
                        side: BorderSide(color: brandBlue.withValues(alpha: 0.5)),
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
                      child: Text('orders.track'.tr()),
                    ),
                    const Spacer(),
                    if (quote != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'orders.total'.tr(),
                            style: textTheme.bodySmall?.copyWith(color: _muted),
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
