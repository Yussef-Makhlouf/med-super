import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:med_super/features/appointments/domain/usecases/list_my_appointments_usecase.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppointmentRepository extends Mock implements AppointmentRepository {}

AppointmentSummary _appointment(String id) => AppointmentSummary(
  appointmentId: id,
  status: 'CONFIRMED',
  slotId: 'slot-$id',
  startAt: DateTime.utc(2026, 9, 18, 9),
  endAt: DateTime.utc(2026, 9, 18, 9, 30),
  doctorClinicAffiliationId: 'affiliation-$id',
  doctorId: 'doctor-$id',
  doctorName: 'Dr $id',
  clinicBranchId: 'branch-$id',
  clinicName: 'Clinic $id',
  clinicAddressLine1: 'Address',
  clinicCity: 'Cairo',
  clinicPhone: '01000000000',
);

void main() {
  late _MockAppointmentRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAppointmentRepository();
    container = ProviderContainer(
      overrides: [
        listMyAppointmentsUseCaseProvider.overrideWithValue(
          ListMyAppointmentsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  MyAppointmentsNotifier notifier() =>
      container.read(myAppointmentsProvider.notifier);

  Future<MyAppointmentsState> loadInitial() =>
      container.read(myAppointmentsProvider.future);

  test('appends a cursor page once, deduplicates overlap, and stops at null',
      () async {
    when(
      () => repository.listMine(
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      return switch (cursor) {
        null => Result.ok(
          AppointmentSummaryPage(items: [_appointment('one')], nextCursor: 'p2'),
        ),
        'p2' => Result.ok(
          AppointmentSummaryPage(
            items: [_appointment('one'), _appointment('two')],
            nextCursor: null,
          ),
        ),
        _ => throw StateError('Unexpected cursor: $cursor'),
      };
    });

    await loadInitial();
    await notifier().loadMore();

    final state = container.read(myAppointmentsProvider).requireValue;
    expect(state.items.map((item) => item.appointmentId), ['one', 'two']);
    expect(state.hasMore, isFalse);
    expect(state.loadMoreFailure, isNull);

    await notifier().loadMore();
    verify(
      () => repository.listMine(status: null, cursor: 'p2', limit: null),
    ).called(1);
  });

  test('keeps the visible list and cursor after a failed page, then retries',
      () async {
    var pageTwoAttempts = 0;
    when(
      () => repository.listMine(
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      if (cursor == null) {
        return Result.ok(
          AppointmentSummaryPage(items: [_appointment('one')], nextCursor: 'p2'),
        );
      }
      pageTwoAttempts++;
      return pageTwoAttempts == 1
          ? const Result.err(
              Failure.server(statusCode: 503, code: 'SERVICE_UNAVAILABLE'),
            )
          : Result.ok(
              AppointmentSummaryPage(items: [_appointment('two')], nextCursor: null),
            );
    });

    await loadInitial();
    await notifier().loadMore();

    var state = container.read(myAppointmentsProvider).requireValue;
    expect(state.items.map((item) => item.appointmentId), ['one']);
    expect(state.nextCursor, 'p2');
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreFailure, isA<ServerFailure>());

    await notifier().loadMore();
    state = container.read(myAppointmentsProvider).requireValue;
    expect(state.items.map((item) => item.appointmentId), ['one', 'two']);
    expect(state.loadMoreFailure, isNull);
  });

  test('shares one in-flight request across repeated load-more taps', () async {
    final pageTwo = Completer<Result<AppointmentSummaryPage>>();
    when(
      () => repository.listMine(
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) {
      final cursor = invocation.namedArguments[#cursor] as String?;
      if (cursor == null) {
        return Future.value(
          Result.ok(
            AppointmentSummaryPage(items: [_appointment('one')], nextCursor: 'p2'),
          ),
        );
      }
      return pageTwo.future;
    });

    await loadInitial();
    final firstTap = notifier().loadMore();
    final secondTap = notifier().loadMore();

    expect(
      container.read(myAppointmentsProvider).requireValue.isLoadingMore,
      isTrue,
    );
    verify(
      () => repository.listMine(status: null, cursor: 'p2', limit: null),
    ).called(1);

    pageTwo.complete(
      Result.ok(
        AppointmentSummaryPage(items: [_appointment('two')], nextCursor: null),
      ),
    );
    await Future.wait([firstTap, secondTap]);

    expect(
      container
          .read(myAppointmentsProvider)
          .requireValue
          .items
          .map((item) => item.appointmentId),
      ['one', 'two'],
    );
  });

  test('surfaces a repeated cursor instead of creating an endless loop',
      () async {
    when(
      () => repository.listMine(
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      return cursor == null
          ? Result.ok(
              AppointmentSummaryPage(items: [_appointment('one')], nextCursor: 'p2'),
            )
          : Result.ok(
              AppointmentSummaryPage(items: [_appointment('two')], nextCursor: 'p2'),
            );
    });

    await loadInitial();
    await notifier().loadMore();

    final state = container.read(myAppointmentsProvider).requireValue;
    expect(state.items.map((item) => item.appointmentId), ['one']);
    expect(state.nextCursor, 'p2');
    expect(state.loadMoreFailure, isA<UnknownFailure>());
  });
}
