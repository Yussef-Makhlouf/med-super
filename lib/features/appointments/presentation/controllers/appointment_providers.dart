import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 moved StateProvider out of the main barrel into this opt-in
// import (still fully supported, just no longer exported by default).
import 'package:flutter_riverpod/legacy.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/appointments/data/datasources/remote/appointments_remote_datasource.dart';
import 'package:med_super/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:med_super/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/confirm_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/create_hold_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/list_my_appointments_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/reschedule_appointment_usecase.dart';

/// Plain (non-codegen) Riverpod providers, same rationale as
/// `doctor_availability_providers.dart`: this addition doesn't need a
/// `build_runner` pass.
final appointmentsRemoteDatasourceProvider =
    Provider<AppointmentsRemoteDatasource>(
      (ref) => AppointmentsRemoteDatasource(ref.watch(dioProvider)),
    );

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepositoryImpl(
    remote: ref.watch(appointmentsRemoteDatasourceProvider),
  ),
);

final createHoldUseCaseProvider = Provider<CreateHoldUseCase>(
  (ref) => CreateHoldUseCase(ref.watch(appointmentRepositoryProvider)),
);

final confirmAppointmentUseCaseProvider = Provider<ConfirmAppointmentUseCase>(
  (ref) => ConfirmAppointmentUseCase(ref.watch(appointmentRepositoryProvider)),
);

final cancelAppointmentUseCaseProvider = Provider<CancelAppointmentUseCase>(
  (ref) => CancelAppointmentUseCase(ref.watch(appointmentRepositoryProvider)),
);

final rescheduleAppointmentUseCaseProvider =
    Provider<RescheduleAppointmentUseCase>(
      (ref) => RescheduleAppointmentUseCase(
        ref.watch(appointmentRepositoryProvider),
      ),
    );

final listMyAppointmentsUseCaseProvider = Provider<ListMyAppointmentsUseCase>(
  (ref) => ListMyAppointmentsUseCase(ref.watch(appointmentRepositoryProvider)),
);

final getAppointmentUseCaseProvider = Provider<GetAppointmentUseCase>(
  (ref) => GetAppointmentUseCase(ref.watch(appointmentRepositoryProvider)),
);

/// Refetch signal for the "My Appointments" list — bumped after a
/// confirm/cancel/reschedule so the list picks up the change without a
/// manual `ref.invalidate` call site at every mutation.
final myAppointmentsRefreshProvider = StateProvider<int>((ref) => 0);

/// A "load more" affordance should only ever render when the backend
/// actually said there's another page — never as an always-on control the
/// user has to discover does nothing once the real count is under a page.
/// Mirrors `PharmacySearchState`/`PharmacySearchNotifier`
/// (`pharmacy_search_providers.dart`) and `DoctorSearchState`
/// (`search_providers.dart`) — same plain (non-codegen) `AsyncNotifier`
/// pattern.
class MyAppointmentsState {
  const MyAppointmentsState({
    required this.items,
    required this.nextCursor,
    required this.isLoadingMore,
  });

  final List<AppointmentSummary> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  MyAppointmentsState copyWith({
    List<AppointmentSummary>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) => MyAppointmentsState(
    items: items ?? this.items,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class MyAppointmentsNotifier extends AsyncNotifier<MyAppointmentsState> {
  @override
  Future<MyAppointmentsState> build() async {
    ref.watch(myAppointmentsRefreshProvider);
    final result = await ref.watch(listMyAppointmentsUseCaseProvider).call();
    final page = result.when(
      ok: (value) => value,
      err: (failure) => throw failure,
    );
    return MyAppointmentsState(
      items: page.items,
      nextCursor: page.nextCursor,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref
          .read(listMyAppointmentsUseCaseProvider)
          .call(cursor: current.nextCursor);
      final page = result.when(
        ok: (value) => value,
        err: (failure) => throw failure,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // A failed "load more" keeps the existing page visible — only the
      // spinner clears, matching PharmacySearchNotifier's behavior.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final myAppointmentsProvider =
    AsyncNotifierProvider<MyAppointmentsNotifier, MyAppointmentsState>(
      MyAppointmentsNotifier.new,
    );

/// `GET /v1/appointments/{id}` (Part 35.17) for `AppointmentDetailScreen`.
/// Also watches [myAppointmentsRefreshProvider] so cancelling/rescheduling
/// from the detail screen itself refreshes the view it's showing.
final appointmentDetailProvider = FutureProvider.autoDispose
    .family<AppointmentSummary, String>((ref, appointmentId) async {
      ref.watch(myAppointmentsRefreshProvider);
      final result = await ref
          .watch(getAppointmentUseCaseProvider)
          .call(appointmentId);
      return result.when(ok: (value) => value, err: (failure) => throw failure);
    });
