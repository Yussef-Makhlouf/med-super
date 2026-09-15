import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/core/widgets/section_header.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';

// ─── model ────────────────────────────────────────────────────────────────────

enum _NotifType {
  appointment,
  orderUpdate,
  labResults,
  appointmentConfirmed,
  prescription,
}

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
    body:
        'لديك موعد مع د. خالد (قلبية) غداً الساعة 9:00 صباحاً في عيادة النور.',
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
  bool _allRead = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'أحمد محمد';

    return Scaffold(
      backgroundColor: AppPalette.paper,
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
                  SectionHeader(title: 'notifications.today'.tr()),
                  const SizedBox(height: 8),
                  ..._todayNotifs.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotifCard(notif: n, forceRead: _allRead),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SectionHeader(title: 'notifications.yesterday'.tr()),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const AppIconTile(icon: SolarIconsBold.bellBing, color: AppPalette.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'home.welcome'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkMuted,
              ),
            ),
            Text(
              displayName,
              style: textTheme.titleMedium?.copyWith(color: AppPalette.ink),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

// ─── title row ────────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.onMarkAllRead});

  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          'notifications.title'.tr(),
          style: textTheme.headlineSmall?.copyWith(color: AppPalette.ink),
        ),
        const Spacer(),
        TextButton(
          onPressed: onMarkAllRead,
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'notifications.mark_all_read'.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: AppPalette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── notification card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif, this.forceRead = false});

  final _Notif notif;
  final bool forceRead;

  bool get _isRead => notif.isRead || forceRead;

  Color _iconColor(_NotifType t, bool isRead) {
    if (isRead) return AppPalette.inkFaint;
    return switch (t) {
      _NotifType.appointment => AppPalette.primary,
      _NotifType.orderUpdate => AppPalette.secondary,
      _NotifType.labResults => AppPalette.warning,
      _NotifType.appointmentConfirmed => AppPalette.success,
      _NotifType.prescription => AppPalette.secondary,
    };
  }

  IconData _icon(_NotifType t) => switch (t) {
    _NotifType.appointment => SolarIconsOutline.calendarMinimalistic,
    _NotifType.orderUpdate => SolarIconsOutline.bag2,
    _NotifType.labResults => SolarIconsOutline.testTube,
    _NotifType.appointmentConfirmed => SolarIconsOutline.checkCircle,
    _NotifType.prescription => SolarIconsOutline.documentMedicine,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRead = _isRead;
    final iconColor = _iconColor(notif.type, isRead);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.resting,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isRead ? Colors.transparent : AppPalette.primary,
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
                      AppIconTile(
                        icon: _icon(notif.type),
                        color: iconColor,
                        size: 44,
                        iconSize: 22,
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
                                      color: AppPalette.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notif.time,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppPalette.inkMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppPalette.inkMuted,
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
