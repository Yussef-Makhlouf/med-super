import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_availability_providers.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_profile_providers.dart';

/// `(id, displayLabel)` — the display label travels with the id selection so
/// the booking summary (`BookingRequest`) can show it without re-resolving
/// against whichever slot list (mock or real) happened to render it.
typedef _SlotSelection = void Function(String id, String label);

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
  String? _selectedDayLabel;
  String? _selectedSlotId;
  String? _selectedTimeLabel;
  String? _selectedClinicBranchId;
  bool _favorited = false;
  bool _navigatingToConfirm = false;

  /// The branch driving availability/booking: the one the patient explicitly
  /// picked (when the doctor has more than one), falling back to the
  /// profile's own primary affiliation otherwise.
  DoctorAffiliation? _effectiveAffiliation(DoctorProfile profile) {
    if (profile.affiliations.isEmpty) return null;
    if (_selectedClinicBranchId != null) {
      final match = profile.affiliations
          .where((a) => a.clinicBranchId == _selectedClinicBranchId)
          .firstOrNull;
      if (match != null) return match;
    }
    return profile.affiliations.first;
  }

  void _onBranchSelected(String clinicBranchId) {
    setState(() {
      _selectedClinicBranchId = clinicBranchId;
      // A different branch has its own independent day/slot list —
      // whatever was selected under the previous branch no longer applies.
      _selectedDayId = null;
      _selectedDayLabel = null;
      _selectedSlotId = null;
      _selectedTimeLabel = null;
    });
  }

  void _book(DoctorProfile profile, DoctorAffiliation affiliation) {
    // Guards against a double-tap/double-click on "Book Now" firing
    // `context.push` twice for the identical route before the first
    // navigation completes — go_router then ends up with two pages
    // computing the same key in its stack at once, tripping the
    // framework's "!keyReservation.contains(key)" duplicate-page
    // assertion on the next frame (the exact HeroControllerScope crash
    // this guards against).
    if (_navigatingToConfirm) return;
    setState(() => _navigatingToConfirm = true);
    context
        .push(
          '/patient/home/appointments/confirm',
          extra: BookingRequest(
            doctorClinicAffiliationId: affiliation.affiliationId,
            slotId: _selectedSlotId!,
            doctorName: profile.name,
            specialty: profile.specialty,
            dayLabel: _selectedDayLabel ?? '',
            timeLabel: _selectedTimeLabel ?? '',
            consultationFee:
                int.tryParse(affiliation.consultationFee) ??
                profile.consultationFee,
            currency: affiliation.currency,
          ),
        )
        .then((_) {
          if (!mounted) return;
          // If the user backed out of the confirm/countdown screen without
          // confirming, the slot they'd picked is now HELD server-side (or
          // already expired back to OPEN) — either way, the id this screen
          // was holding onto is stale, and the cached slot list this
          // screen's `doctorAvailabilityProvider` is showing still reflects
          // the pre-hold state. Explicitly invalidating here — right after
          // this screen resumes, definitely still mounted — rather than
          // relying on `BookingConfirmScreen.dispose` to bump a shared
          // refresh signal is deliberate: a provider mutation fired from
          // another widget's `dispose()` isn't guaranteed to still be
          // observed by this one by the time it runs.
          ref.invalidate(
            doctorAvailabilityProvider((
              doctorId: widget.doctorId,
              clinicBranchId: affiliation.clinicBranchId,
              ianaTimezone: affiliation.ianaTimezone,
            )),
          );
          setState(() {
            _navigatingToConfirm = false;
            // Clearing (rather than leaving it selected) prevents
            // re-submitting the same dead slot and getting "This slot is
            // no longer open."
            _selectedDayId = null;
            _selectedDayLabel = null;
            _selectedSlotId = null;
            _selectedTimeLabel = null;
          });
        });
  }

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
        onRetry: () => ref.invalidate(doctorProfileProvider(widget.doctorId)),
        data: (profile) {
          final defaultDay = profile.availableDays.isNotEmpty
              ? profile.availableDays.first
              : null;
          final affiliation = _effectiveAffiliation(profile);
          return _ProfileBody(
            profile: profile,
            affiliation: affiliation,
            selectedDayId: _selectedDayId ?? defaultDay?.id,
            selectedSlotId: _selectedSlotId,
            onBranchSelected: _onBranchSelected,
            onDaySelected: (id, label) => setState(() {
              _selectedDayId = id;
              _selectedDayLabel = label;
              _selectedSlotId = null;
              _selectedTimeLabel = null;
            }),
            onSlotSelected: (id, label) => setState(() {
              // A time can be picked while still on the auto-selected
              // default day (no explicit day tap) — capture that day's
              // label here too, so BookingRequest.dayLabel is never blank.
              _selectedDayId ??= defaultDay?.id;
              _selectedDayLabel ??= defaultDay == null
                  ? null
                  : '${defaultDay.label} ${defaultDay.dayNumber}';
              _selectedSlotId = id;
              _selectedTimeLabel = label;
            }),
          );
        },
      ),
      bottomNavigationBar: asyncProfile.maybeWhen(
        data: (profile) {
          final affiliation = _effectiveAffiliation(profile);
          return _BottomBar(
            fee: int.tryParse(affiliation?.consultationFee ?? '') ??
                profile.consultationFee,
            currency: affiliation?.currency ?? profile.currency,
            // Real Phase 4 booking (File 10 §2.3) needs both a selected slot
            // and a resolved branch affiliation — null only when the doctor
            // genuinely has no visible affiliation, so the button stays
            // disabled rather than sending a request that's guaranteed to
            // 404. Also disabled mid-navigation (see `_book`'s doc comment)
            // to prevent a double-tap crash.
            onBook:
                (affiliation != null &&
                    _selectedSlotId != null &&
                    !_navigatingToConfirm)
                ? () => _book(profile, affiliation)
                : null,
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.affiliation,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onBranchSelected,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final DoctorProfile profile;
  final DoctorAffiliation? affiliation;
  final String? selectedDayId;
  final String? selectedSlotId;
  final ValueChanged<String> onBranchSelected;
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context) {
    // Deliberately does NOT pre-resolve selectedDayId against
    // profile.availableDays here: _AvailabilitySection may render a
    // completely different (real, backend-sourced) day list with different
    // ids, and _SlotsCard already does its own "fall back to first day"
    // resolution against whichever list it actually receives.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeaderCard(profile: profile, affiliation: affiliation),
        const SizedBox(height: 12),
        _AboutCard(profile: profile),
        // Only worth showing a branch picker when there's an actual choice
        // to make — a doctor affiliated with a single branch has nothing to
        // pick between.
        if (profile.affiliations.length > 1) ...[
          const SizedBox(height: 12),
          _BranchPickerCard(
            affiliations: profile.affiliations,
            selectedClinicBranchId: affiliation?.clinicBranchId,
            onSelected: onBranchSelected,
          ),
        ],
        const SizedBox(height: 12),
        _AvailabilitySection(
          profile: profile,
          affiliation: affiliation,
          selectedDayId: selectedDayId,
          selectedSlotId: selectedSlotId,
          onDaySelected: onDaySelected,
          onSlotSelected: onSlotSelected,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _BranchPickerCard extends StatelessWidget {
  const _BranchPickerCard({
    required this.affiliations,
    required this.selectedClinicBranchId,
    required this.onSelected,
  });

  final List<DoctorAffiliation> affiliations;
  final String? selectedClinicBranchId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                color: brandBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'doctor_profile.choose_branch'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...affiliations.map((a) {
            final isSelected = a.clinicBranchId == selectedClinicBranchId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(a.clinicBranchId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brandBlue.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? brandBlue
                          : const Color(0xFFE5EAF2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? brandBlue : _muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // The branch's own address, not the clinic
                              // brand name — every branch of the same
                              // doctor shares that name, so it can't tell
                              // branches apart on its own.
                              a.addressLine1.isNotEmpty
                                  ? a.addressLine1
                                  : a.clinicName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: _ink,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            if (a.addressLine1.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                a.city.isNotEmpty
                                    ? '${a.clinicName} · ${a.city}'
                                    : a.clinicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: _muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile, required this.affiliation});

  final DoctorProfile profile;
  final DoctorAffiliation? affiliation;

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
              // The "online now" dot (profile.isOnline) is removed here —
              // no backend column backs it at all
              // (`GetDoctorUseCase`'s doc comment), so it always defaulted
              // to false and never rendered against a real backend.
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
            style: textTheme.bodyMedium?.copyWith(color: _muted),
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
              if (affiliation != null)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(
                    '/patient/home/clinic-branches/${affiliation!.clinicBranchId}',
                  ),
                  child: _InfoChip(
                    icon: Icons.local_hospital_outlined,
                    label: affiliation!.clinicName,
                    iconColor: brandBlue,
                  ),
                )
              else
                _InfoChip(
                  icon: Icons.local_hospital_outlined,
                  label: profile.clinicName,
                  iconColor: brandBlue,
                ),
              // Rating/review-count chip removed: `rating_avg`/
              // `rating_count` are real columns but no reviews feature
              // exists to ever write a non-zero value to them (the
              // `reviews` module is POSTPONEd) — every doctor shows
              // "0.0 (0)" forever, not a meaningful signal.
              //
              // Languages chip removed: `GetDoctorUseCase` doesn't return
              // this field at all (see its doc comment), so it always
              // rendered as an icon with no text next to it.
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
    final hasBio = profile.bio.trim().isNotEmpty;
    final hasCredentials = profile.qualifications.isNotEmpty;
    // Nothing to show yet (seeded/demo doctors often have no bio or
    // credentials filled in) — an empty card with just a header reads as
    // broken, so skip rendering it entirely rather than show blank space.
    if (!hasBio && !hasCredentials) return const SizedBox.shrink();

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
          if (hasBio) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio,
              style: textTheme.bodyMedium?.copyWith(
                color: _ink.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
          if (hasBio && hasCredentials) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
          ] else if (hasCredentials) ...[
            const SizedBox(height: 14),
          ],
          // Fellowships row removed (2026-09-03) — no backend column backs
          // it at all (`GetDoctorUseCase`'s doc comment), so it always
          // rendered an empty list against a real backend.
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
        ],
      ),
    );
  }
}

/// Real Phase 3 availability (`GET /v1/doctors/{doctorId}/slots`) for
/// whichever branch is currently resolved (the patient's explicit pick, or
/// the profile's primary affiliation — see
/// `_DoctorDetailsScreenState._effectiveAffiliation`); falls back to the
/// profile's own (mock-only) `availableDays` only when the doctor has no
/// visible affiliation at all. Selecting a slot here feeds `_BottomBar`'s
/// "Book Now," which additionally needs the resolved affiliation's id
/// (Phase 4 is real now).
class _AvailabilitySection extends ConsumerWidget {
  const _AvailabilitySection({
    required this.profile,
    required this.affiliation,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final DoctorProfile profile;
  final DoctorAffiliation? affiliation;
  final String? selectedDayId;
  final String? selectedSlotId;
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicBranchId = affiliation?.clinicBranchId;
    if (clinicBranchId == null) {
      return _SlotsCard(
        days: profile.availableDays,
        selectedDayId: selectedDayId,
        selectedSlotId: selectedSlotId,
        onDaySelected: onDaySelected,
        onSlotSelected: onSlotSelected,
      );
    }

    final params = (
      doctorId: profile.id,
      clinicBranchId: clinicBranchId,
      ianaTimezone: affiliation?.ianaTimezone ?? profile.ianaTimezone,
    );
    final asyncDays = ref.watch(doctorAvailabilityProvider(params));

    return AsyncValueView(
      value: asyncDays,
      onRetry: () => ref.invalidate(doctorAvailabilityProvider(params)),
      loadingWidget: const _Card(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      data: (days) => days.isEmpty
          ? _Card(
              child: SizedBox(
                height: 64,
                child: Center(child: Text('doctor_profile.no_slots'.tr())),
              ),
            )
          : _SlotsCard(
              days: days,
              selectedDayId: selectedDayId,
              selectedSlotId: selectedSlotId,
              onDaySelected: onDaySelected,
              onSlotSelected: onSlotSelected,
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
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected =
        days.where((d) => d.id == selectedDayId).firstOrNull ??
        days.firstOrNull;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: brandBlue,
                size: 20,
              ),
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
                  onTap: () =>
                      onDaySelected(day.id, '${day.label} ${day.dayNumber}'),
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
                  onTap: enabled
                      ? () => onSlotSelected(slot.id, slot.label)
                      : null,
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
                        decoration: enabled ? null : TextDecoration.lineThrough,
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
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final feeLabel = currency == 'EGP' ? '$fee ج.م' : '$fee $currency';
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _muted),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _ink.withValues(alpha: 0.8)),
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
