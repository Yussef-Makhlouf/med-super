import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_availability_providers.dart';

typedef DoctorOpenSlotsParams = ({
  String doctorId,
  String clinicBranchId,
  DateTime? from,
  DateTime? to,
});

/// Flat `OPEN` slots for one of the doctor's own branches, used by the
/// reschedule picker and the home-screen day timeline.
///
/// Deliberately a plain `FutureProvider.family` rather than `@riverpod` —
/// the same convention `doctor_availability_providers.dart` uses for small
/// additions, so this needs no `build_runner` pass.
///
/// `from`/`to` are optional: omitted, the backend defaults to
/// `[now, now+14days)` (File 12 Part 33.16) — right for "any upcoming open
/// slot" pickers (reschedule, walk-in booking). A caller showing a single
/// specific day (the home-screen timeline) must pass that day's own
/// midnight-to-midnight bounds instead, because `from` defaulting to the
/// exact current instant — not that day's start — would silently exclude
/// every slot earlier today, and exclude the whole day entirely once it's in
/// the past.
///
/// It reuses `doctorSlotsRepositoryProvider` rather than adding a second
/// slots client. One caveat worth knowing: that endpoint applies the Part 32
/// visibility chain for non-Admin callers, so a doctor whose own branch is
/// not `VERIFIED` gets an empty list here — which is correct, since no slots
/// are generated for such a branch in the first place.
final doctorOpenSlotsProvider =
    FutureProvider.family<List<DoctorSlot>, DoctorOpenSlotsParams>((
      ref,
      params,
    ) async {
      final result = await ref
          .watch(doctorSlotsRepositoryProvider)
          .getDoctorSlots(
            doctorId: params.doctorId,
            clinicBranchId: params.clinicBranchId,
            from: params.from,
            to: params.to,
          );
      return result.when(ok: (value) => value, err: (failure) => throw failure);
    });
