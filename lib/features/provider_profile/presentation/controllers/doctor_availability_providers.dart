import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/doctor_slots_remote_datasource.dart';
import 'package:med_super/features/provider_profile/data/repositories/doctor_slots_repository_impl.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_slots_repository.dart';
import 'package:med_super/features/provider_profile/domain/usecases/get_doctor_availability_usecase.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`, so
/// this Phase 3 addition doesn't require a `build_runner` regeneration pass.
final doctorSlotsRemoteDatasourceProvider =
    Provider<DoctorSlotsRemoteDatasource>(
      (ref) => DoctorSlotsRemoteDatasource(ref.watch(dioProvider)),
    );

final doctorSlotsRepositoryProvider = Provider<DoctorSlotsRepository>(
  (ref) => DoctorSlotsRepositoryImpl(
    remote: ref.watch(doctorSlotsRemoteDatasourceProvider),
  ),
);

final getDoctorAvailabilityUseCaseProvider =
    Provider<GetDoctorAvailabilityUseCase>(
      (ref) => GetDoctorAvailabilityUseCase(
        ref.watch(doctorSlotsRepositoryProvider),
      ),
    );

typedef DoctorAvailabilityParams = ({
  String doctorId,
  String clinicBranchId,
  String? ianaTimezone,
});

/// Watches [myAppointmentsRefreshProvider] so a slot that was just booked
/// (via [doctor_details_screen]'s "Book Now") or rescheduled away from
/// disappears from this list on the next visit, instead of this
/// `FutureProvider`'s cached result — never invalidated on its own —
/// silently continuing to show a now-`BOOKED` slot as still `OPEN` until
/// the user manually pulls to refresh or the app restarts.
final doctorAvailabilityProvider =
    FutureProvider.family<List<AvailableDay>, DoctorAvailabilityParams>((
      ref,
      params,
    ) async {
      ref.watch(myAppointmentsRefreshProvider);
      final result = await ref
          .watch(getDoctorAvailabilityUseCaseProvider)
          .call(
            doctorId: params.doctorId,
            clinicBranchId: params.clinicBranchId,
            ianaTimezone: params.ianaTimezone,
          );
      return result.when(ok: (value) => value, err: (failure) => throw failure);
    });
