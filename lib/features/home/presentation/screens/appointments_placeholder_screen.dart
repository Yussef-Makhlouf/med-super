import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

// ─── model ────────────────────────────────────────────────────────────────────

enum _ApptStatus { confirmed, pending, completed }

class _Appointment {
  const _Appointment({
    required this.doctorName,
    required this.specialty,
    required this.avatarInitials,
    required this.avatarColor,
    required this.status,
    required this.date,
    required this.time,
    this.location,
  });

  final String doctorName;
  final String specialty;
  final String avatarInitials;
  final Color avatarColor;
  final _ApptStatus status;
  final String date;
  final String time;
  final String? location;
}

const _upcomingAppts = [
  _Appointment(
    doctorName: 'د. ليلى العتيبي',
    specialty: 'استشارية أمراض القلب',
    avatarInitials: 'لع',
    avatarColor: Color(0xFFE8F0FE),
    status: _ApptStatus.confirmed,
    date: 'غداً، 14 أكتوبر',
    time: '10:30 صباحاً',
  ),
  _Appointment(
    doctorName: 'د. فهد الشمري',
    specialty: 'أخصائي الأمراض الجلدية',
    avatarInitials: 'فش',
    avatarColor: Color(0xFFFFF3E0),
    status: _ApptStatus.pending,
    date: 'الخميس، 17 أكتوبر',
    time: '04:15 مساءً',
    location: 'مستشفى سليمان الحبيب، الطابق الثاني',
  ),
];

const _pastAppts = [
  _Appointment(
    doctorName: 'د. سارة الحربي',
    specialty: 'طب الأطفال',
    avatarInitials: 'سح',
    avatarColor: Color(0xFFE8F5E9),
    status: _ApptStatus.completed,
    date: 'الثلاثاء، 8 أكتوبر',
    time: '11:00 صباحاً',
    location: 'عيادة النور الطبية، الدور الأول',
  ),
];

// ─── screen ───────────────────────────────────────────────────────────────────

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends ConsumerState<PatientAppointmentsScreen> {
  static const _pageBg = Color(0xFFF3F6FB);
  static const _muted = Color(0xFF8A94A6);

  int _selectedTab = 0; // 0 = upcoming, 1 = past

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final displayName = session?.user.displayName?.trim().isNotEmpty == true
        ? session!.user.displayName!
        : 'أحمد محمد';

    final appts = _selectedTab == 0 ? _upcomingAppts : _pastAppts;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ApptHeader(displayName: displayName),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'appointments.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TabRow(
                selectedTab: _selectedTab,
                onTabChanged: (t) => setState(() => _selectedTab = t),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appts.isEmpty
                  ? Center(
                      child: Text(
                        'appointments.empty'.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: _muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: appts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) =>
                          _AppointmentCard(appt: appts[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header ───────────────────────────────────────────────────────────────────

class _ApptHeader extends StatelessWidget {
  const _ApptHeader({required this.displayName});

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _TabBtn(
            label: 'appointments.tab_upcoming'.tr(),
            isActive: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabBtn(
            label: 'appointments.tab_past'.tr(),
            isActive: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
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
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── appointment card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appt});

  final _Appointment appt;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);
  static const _divider = Color(0xFFEFF2F7);

  Color _statusColor(_ApptStatus s) => switch (s) {
    _ApptStatus.confirmed => brandBlue,
    _ApptStatus.pending => const Color(0xFFF59E0B),
    _ApptStatus.completed => const Color(0xFF22C55E),
  };

  String _statusLabel(_ApptStatus s) => switch (s) {
    _ApptStatus.confirmed => 'appointments.status_confirmed'.tr(),
    _ApptStatus.pending => 'appointments.status_pending'.tr(),
    _ApptStatus.completed => 'appointments.status_completed'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(appt.status);

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor row: avatar on right (first in RTL), pill on left (last in RTL)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: appt.avatarColor,
                child: Text(
                  appt.avatarInitials,
                  style: textTheme.titleSmall?.copyWith(
                    color: brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.doctorName,
                      style: textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appt.specialty,
                      style: textTheme.bodySmall?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(label: _statusLabel(appt.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 12),
          // Date & time row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                appt.date,
                style: textTheme.bodySmall?.copyWith(color: _muted),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                appt.time,
                style: textTheme.bodySmall?.copyWith(color: _muted),
              ),
            ],
          ),
          if (appt.location != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appt.location!,
                    style: textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 12),
          // Action buttons
          _ActionButtons(status: appt.status),
        ],
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.status});

  final _ApptStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _ApptStatus.confirmed => Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text('appointments.join'.tr()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('appointments.edit'.tr()),
            ),
          ),
        ],
      ),
      _ApptStatus.pending => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('appointments.view_location'.tr()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFECACA)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('appointments.cancel'.tr()),
            ),
          ),
        ],
      ),
      _ApptStatus.completed => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: brandBlue,
                side: BorderSide(color: brandBlue.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('appointments.rebook'.tr()),
            ),
          ),
        ],
      ),
    };
  }
}
