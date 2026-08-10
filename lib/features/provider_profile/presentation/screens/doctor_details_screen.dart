import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_profile_providers.dart';

const _ink = Color(0xFF1A2B4A);
const _muted = Color(0xFF8A94A6);

/// Doctor details — matches Figma RTL profile screen.
class DoctorDetailsScreen extends ConsumerStatefulWidget {
  const DoctorDetailsScreen({required this.doctorId, super.key});

  final String doctorId;

  @override
  ConsumerState<DoctorDetailsScreen> createState() =>
      _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends ConsumerState<DoctorDetailsScreen> {
  static const _pageBg = Color(0xFFF3F6FB);

  String? _selectedDayId;
  String? _selectedSlotId;
  bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(doctorProfileProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: brandBlue),
        ),
        title: Text(
          'doctor_profile.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: brandBlue),
          ),
          IconButton(
            onPressed: () => setState(() => _favorited = !_favorited),
            icon: Icon(
              _favorited ? Icons.favorite : Icons.favorite_border,
              color: brandBlue,
            ),
          ),
        ],
      ),
      body: AsyncValueView(
        value: asyncProfile,
        onRetry: () =>
            ref.invalidate(doctorProfileProvider(widget.doctorId)),
        data: (profile) => _ProfileBody(
          profile: profile,
          selectedDayId: _selectedDayId ??
              (profile.availableDays.isNotEmpty
                  ? profile.availableDays.first.id
                  : null),
          selectedSlotId: _selectedSlotId,
          onDaySelected: (id) => setState(() {
            _selectedDayId = id;
            _selectedSlotId = null;
          }),
          onSlotSelected: (id) => setState(() => _selectedSlotId = id),
        ),
      ),
      bottomNavigationBar: asyncProfile.maybeWhen(
        data: (profile) => _BottomBar(
          fee: profile.consultationFee,
          currency: profile.currency,
          onBook: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('doctor_profile.booking_soon'.tr())),
            );
          },
        ),
        orElse: () => null,
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final DoctorProfile profile;
  final String? selectedDayId;
  final String? selectedSlotId;
  final ValueChanged<String> onDaySelected;
  final ValueChanged<String> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    AvailableDay? selectedDay;
    for (final d in profile.availableDays) {
      if (d.id == selectedDayId) {
        selectedDay = d;
        break;
      }
    }
    selectedDay ??=
        profile.availableDays.isEmpty ? null : profile.availableDays.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(profile: profile),
        const SizedBox(height: 12),
        _AboutCard(profile: profile),
        const SizedBox(height: 12),
        _SlotsCard(
          days: profile.availableDays,
          selectedDayId: selectedDay?.id,
          selectedSlotId: selectedSlotId,
          onDaySelected: onDaySelected,
          onSlotSelected: onSlotSelected,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final DoctorProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFDCE8FF),
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? const Icon(Icons.person, size: 48, color: brandBlue)
                    : null,
              ),
              if (profile.isOnline)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: textTheme.titleLarge?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: brandBlue, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.specialty,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: _muted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.work_outline,
                label: 'search.experience_years'.tr(
                  args: ['${profile.experienceYears}'],
                ),
              ),
              _InfoChip(
                icon: Icons.local_hospital_outlined,
                label: profile.clinicName,
                iconColor: brandBlue,
              ),
              _InfoChip(
                icon: Icons.star,
                iconColor: const Color(0xFFF59E0B),
                label:
                    '${profile.rating.toStringAsFixed(1)} (${profile.reviewCount} ${'doctor_profile.reviews'.tr()})',
              ),
              _InfoChip(
                icon: Icons.language,
                label: profile.languages.join('، '),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.profile});

  final DoctorProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: brandBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'doctor_profile.about'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.bio,
            style: textTheme.bodyMedium?.copyWith(
              color: _ink.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...profile.qualifications.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CredentialRow(
                icon: Icons.school_outlined,
                title: 'doctor_profile.qualifications'.tr(),
                value: q,
              ),
            ),
          ),
          ...profile.fellowships.map(
            (f) => _CredentialRow(
              icon: Icons.military_tech_outlined,
              title: 'doctor_profile.fellowships'.tr(),
              value: f,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsCard extends StatelessWidget {
  const _SlotsCard({
    required this.days,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final List<AvailableDay> days;
  final String? selectedDayId;
  final String? selectedSlotId;
  final ValueChanged<String> onDaySelected;
  final ValueChanged<String> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected =
        days.where((d) => d.id == selectedDayId).firstOrNull ?? days.firstOrNull;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: brandBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'doctor_profile.available_slots'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day.id == selectedDayId;
                return InkWell(
                  onTap: () => onDaySelected(day.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? brandBlue.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? brandBlue : const Color(0xFFE5EAF2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${day.label} ${day.dayNumber}',
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected ? brandBlue : _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (selected != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.slots.map((slot) {
                final isSelected = slot.id == selectedSlotId;
                final enabled = slot.available;
                return InkWell(
                  onTap: enabled ? () => onSlotSelected(slot.id) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 84,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !enabled
                          ? const Color(0xFFF3F4F6)
                          : isSelected
                              ? brandBlue.withValues(alpha: 0.08)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !enabled
                            ? const Color(0xFFE5E7EB)
                            : isSelected
                                ? brandBlue
                                : const Color(0xFFE5EAF2),
                      ),
                    ),
                    child: Text(
                      slot.label,
                      style: textTheme.labelLarge?.copyWith(
                        color: !enabled
                            ? _muted
                            : isSelected
                                ? brandBlue
                                : _ink,
                        decoration:
                            enabled ? null : TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.fee,
    required this.currency,
    required this.onBook,
  });

  final int fee;
  final String currency;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final feeLabel =
        currency == 'EGP' ? '$fee ج.م' : '$fee $currency';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'home.book_now'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'doctor_profile.fee_label'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _muted,
                      ),
                ),
                Text(
                  feeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor = _muted,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _ink.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: brandBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
