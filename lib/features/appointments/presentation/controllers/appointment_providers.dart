import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 moved StateProvider out of the main barrel into this opt-in
// import (still fully supported, just no longer exported by default).
import 'package:flutter_riverpod/legacy.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/features/appointments/data/datasources/remote/appointments_remote_datasource.dart';
import 'package:med_super/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:med_super/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/confirm_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/create_hold_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:med_super/features/appointments/domain/usecases/initiate_online_payment_usecase.dart';
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

final initiateOnlinePaymentUseCaseProvider =
    Provider<InitiateOnlinePaymentUseCase>(
      (ref) =>
          InitiateOnlinePaymentUseCase(ref.watch(appointmentRepositoryProvider)),
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
    this.loadMoreFailure,
  });

  final List<AppointmentSummary> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  MyAppointmentsState copyWith({
    List<AppointmentSummary>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => MyAppointmentsState(
    items: items ?? this.items,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}

class MyAppointmentsNotifier extends AsyncNotifier<MyAppointmentsState> {
  Future<void>? _loadMoreInFlight;
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

  /// Loads exactly one cursor page. Concurrent taps share the same future,
  /// so a slow network response cannot issue the same cursor request twice.
  Future<void> loadMore() {
    final inFlight = _loadMoreInFlight;
    if (inFlight != null) return inFlight;

    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return Future.value();
    }

    final cursor = current.nextCursor!;
    late final Future<void> request;
    request = _loadMorePage(current: current, cursor: cursor).whenComplete(() {
      if (identical(_loadMoreInFlight, request)) {
        _loadMoreInFlight = null;
      }
    });
    _loadMoreInFlight = request;
    return request;
  }

  Future<void> _loadMorePage({
    required MyAppointmentsState current,
    required String cursor,
  }) async {
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );
    try {
      final result = await ref
          .read(listMyAppointmentsUseCaseProvider)
          .call(cursor: cursor);

      result.when(
        ok: (page) {
          // Page boundaries can overlap when records change between requests.
          // Keep the first copy of each stable appointment id.
          final knownIds = current.items.map((item) => item.appointmentId).toSet();
          final appendedItems = [
            ...current.items,
            for (final item in page.items)
              if (knownIds.add(item.appointmentId)) item,
          ];

          // Do not let a malformed response create an endless request loop.
          if (page.nextCursor == cursor) {
            _finishLoadMoreFailure(
              current,
              cursor,
              Failure.unknown(
                StateError('Appointment pagination returned the same cursor.'),
                StackTrace.current,
              ),
            );
            return;
          }

          if (!_isCurrentLoadMoreRequest(cursor)) return;
          state = AsyncData(
            current.copyWith(
              items: appendedItems,
              nextCursor: page.nextCursor,
              clearNextCursor: page.nextCursor == null,
              isLoadingMore: false,
              clearLoadMoreFailure: true,
            ),
          );
        },
        err: (failure) => _finishLoadMoreFailure(current, cursor, failure),
      );
    } catch (error, stackTrace) {
      _finishLoadMoreFailure(
        current,
        cursor,
        Failure.unknown(error, stackTrace),
      );
    }
  }

  bool _isCurrentLoadMoreRequest(String cursor) {
    final visible = state.value;
    return visible != null &&
        visible.isLoadingMore &&
        visible.nextCursor == cursor;
  }

  void _finishLoadMoreFailure(
    MyAppointmentsState current,
    String cursor,
    Failure failure,
  ) {
    if (!_isCurrentLoadMoreRequest(cursor)) return;
    // A failed page is never destructive: the list and retry cursor remain.
    state = AsyncData(
      current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
    );
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
