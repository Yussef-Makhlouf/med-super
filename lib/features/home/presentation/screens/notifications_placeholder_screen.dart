import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

// ─── model ────────────────────────────────────────────────────────────────────

enum _NotifType { appointment, orderUpdate, labResults, appointmentConfirmed, prescription }

class _Notif {
  const _Notif({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  final _NotifType type;
  final String title;
  final String body;
  final String time;
  final bool isRead;
}

const _todayNotifs = [
  _Notif(
    type: _NotifType.appointment,
    title: 'تذكير بموعد العيادة',
    body: 'لديك موعد مع د. خالد (قلبية) غداً الساعة 9:00 صباحاً في عيادة النور.',
    time: 'الآن',
    isRead: false,
  ),
  _Notif(
    type: _NotifType.orderUpdate,
    title: 'تحديث حالة الطلب',
    body: 'أدويتك قيد التوصيل الآن. المندوب في الطريق إليك (رقم الطلب: #9824).',
    time: 'منذ ساعتين',
    isRead: false,
  ),
  _Notif(
    type: _NotifType.labResults,
    title: 'نتائج التحاليل جاهزة',
    body: 'تم إصدار نتائج فحص الدم الشامل الخاص بك. يمكنك الاطلاع عليها الآن.',
    time: 'منذ 5 ساعات',
    isRead: false,
  ),
];

const _yesterdayNotifs = [
  _Notif(
    type: _NotifType.appointmentConfirmed,
    title: 'تم تأكيد الموعد',
    body: 'تم تأكيد موعدك بنجاح لزيارة د. فاطمة (أطفال) في مركز الحياة الطبي.',
    time: '2:30 م',
    isRead: true,
  ),
  _Notif(
    type: _NotifType.prescription,
    title: 'وصفة طبية جديدة',
    body: 'قام د. أحمد بإضافة وصفة طبية جديدة لملفك. يمكنك طلب الأدوية الآن.',
    time: '9:15 ص',
    isRead: true,
  ),
];

// ─── screen ───────────────────────────────────────────────────────────────────

class PatientNotificationsScreen extends ConsumerStatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  ConsumerState<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends ConsumerState<PatientNotificationsScreen> {
  static const _pageBg = Color(0xFFF3F6FB);

  bool _allRead = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName =
        session?.user.displayName?.trim().isNotEmpty == true
            ? session!.user.displayName!
            : 'أحمد محمد';

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _NotifHeader(displayName: displayName),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TitleRow(
                onMarkAllRead: () => setState(() => _allRead = true),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  _SectionHeader(label: 'notifications.today'.tr()),
                  const SizedBox(height: 8),
                  ..._todayNotifs.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotifCard(
                        notif: n,
                        forceRead: _allRead,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionHeader(label: 'notifications.yesterday'.tr()),
                  const SizedBox(height: 8),
                  ..._yesterdayNotifs.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotifCard(notif: n, forceRead: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header (same pattern as other patient screens) ───────────────────────────

class _NotifHeader extends StatelessWidget {
  const _NotifHeader({required this.displayName});

  final String displayName;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: brandBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
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
      ],
    );
  }
}

// ─── title row ────────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.onMarkAllRead});

  final VoidCallback onMarkAllRead;

  static const _ink = Color(0xFF1A2B4A);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          'notifications.title'.tr(),
          style: textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onMarkAllRead,
          style: TextButton.styleFrom(
            foregroundColor: brandBlue,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'notifications.mark_all_read'.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF1A2B4A),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ─── notification card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif, this.forceRead = false});

  final _Notif notif;
  final bool forceRead;

  bool get _isRead => notif.isRead || forceRead;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  Color _iconBg(_NotifType t, bool isRead) {
    if (isRead) return const Color(0xFFE5E7EB);
    return switch (t) {
      _NotifType.appointment => brandBlue,
      _NotifType.orderUpdate => const Color(0xFF0891B2),
      _NotifType.labResults => const Color(0xFFF59E0B),
      _NotifType.appointmentConfirmed => const Color(0xFF6B7280),
      _NotifType.prescription => const Color(0xFF6B7280),
    };
  }

  Color _iconFg(bool isRead) =>
      isRead ? const Color(0xFF9CA3AF) : Colors.white;

  IconData _icon(_NotifType t) => switch (t) {
        _NotifType.appointment => Icons.calendar_month_outlined,
        _NotifType.orderUpdate => Icons.local_pharmacy_outlined,
        _NotifType.labResults => Icons.science_outlined,
        _NotifType.appointmentConfirmed => Icons.check_circle_outline,
        _NotifType.prescription => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRead = _isRead;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isRead ? Colors.transparent : brandBlue,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _iconBg(notif.type, isRead),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _icon(notif.type),
                          size: 22,
                          color: _iconFg(isRead),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: _ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notif.time,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: textTheme.bodySmall?.copyWith(
                                color: _muted,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
