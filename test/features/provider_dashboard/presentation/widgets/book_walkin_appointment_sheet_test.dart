import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/book_walkin_appointment_sheet.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// Pumps in short real-time bursts (mirroring `pumpLocalizedWidget`'s own
/// loop) until [finder] appears or the budget is spent — the mock Dio round
/// trip is real async I/O, not fake-clock work, so a couple of
/// `tester.pump()` calls alone never see it land. Not `pumpAndSettle()`:
/// the loading state renders a `CircularProgressIndicator`, whose
/// perpetual animation makes `pumpAndSettle` time out rather than return
/// once data has actually arrived.
Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && tester.any(finder) == false; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Street address of the seeded VERIFIED/ACTIVE Cairo branch
/// (`mock_responses.dart`) — what its branch chip shows.
const _cairoBranchLine = '12 شارع التحرير';

/// Street address of the seeded PENDING Alexandria branch, which must never
/// be offered for booking.
const _alexBranchLine = '5 الكورنيش';

/// Slot chips render `formatAppointmentTime` output, e.g. `09:30 AM`.
final _slotChips = find.textContaining(RegExp(r'^\d{2}:\d{2} (AM|PM)$'));

/// Exercises the real Dio + `MockInterceptor` stack end to end: branch pick
/// -> slot pick -> patient phone/name -> submit -> the walk-in booking
/// mock in `mock_responses.dart` (`POST
/// .../appointments/branch/{clinicBranchId}/create`).
void main() {
  testWidgets(
    'books a walk-in appointment through branch -> slot -> patient -> submit',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      bool? bookedResult;

      await pumpLocalizedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              bookedResult = await showBookWalkInAppointmentSheet(
                context,
                doctorId: 'doctor-1',
              );
            },
            child: const Text('open'),
          ),
        ),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.tap(find.text('open'));
      await tester.pump();

      // Branch chips are labelled by city + street address (not the shared
      // clinic name, which doesn't distinguish branches).
      final branchFinder = find.text(_cairoBranchLine);
      await _pumpUntilFound(tester, branchFinder);

      // Only the VERIFIED/ACTIVE branch (Cairo) is offered — the second
      // seeded branch is PENDING verification and must not appear.
      expect(branchFinder, findsOneWidget);
      expect(find.text(_alexBranchLine), findsNothing);

      await tester.tap(branchFinder);
      await tester.pump();

      final slotTiles = _slotChips;
      await _pumpUntilFound(tester, slotTiles);

      // A slot chip renders a formatted time (`hh:mm AM/PM`) for the
      // auto-selected earliest day — tap the first one.
      expect(slotTiles, findsWidgets);
      await tester.tap(slotTiles.first);
      await tester.pump();

      // Patient fields now show.
      final phoneField = find.widgetWithText(
        TextFormField,
        'رقم هاتف المريض',
      );
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '01009998887');

      final nameField = find.widgetWithText(TextFormField, 'اسم المريض');
      await tester.enterText(nameField, 'سارة أحمد');

      final submitButton = find.widgetWithText(FilledButton, 'تأكيد الحجز');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.pump();

      await tester.tap(submitButton);
      await tester.pump();
      for (var i = 0; i < 40 && bookedResult == null; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(bookedResult, isTrue);
    },
  );

  testWidgets('rejects an invalid phone before submitting', (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showBookWalkInAppointmentSheet(
            context,
            doctorId: 'doctor-1',
          ),
          child: const Text('open'),
        ),
      ),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    final branchFinder = find.text(_cairoBranchLine);
    await _pumpUntilFound(tester, branchFinder);

    await tester.tap(branchFinder);
    await tester.pump();

    final slotTiles = _slotChips;
    await _pumpUntilFound(tester, slotTiles);

    await tester.tap(slotTiles.first);
    await tester.pump();

    final phoneField = find.widgetWithText(TextFormField, 'رقم هاتف المريض');
    await tester.enterText(phoneField, '0100');

    final submitButton = find.widgetWithText(FilledButton, 'تأكيد الحجز');
    await tester.ensureVisible(submitButton);
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pump();

    expect(
      find.text('أدخل رقم هاتف مصري صحيح، مثل 01001234567'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a blank patient name before submitting', (
    tester,
  ) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showBookWalkInAppointmentSheet(
            context,
            doctorId: 'doctor-1',
          ),
          child: const Text('open'),
        ),
      ),
      overrides: [dioProvider.overrideWithValue(dio)],
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    final branchFinder = find.text(_cairoBranchLine);
    await _pumpUntilFound(tester, branchFinder);

    await tester.tap(branchFinder);
    await tester.pump();

    final slotTiles = _slotChips;
    await _pumpUntilFound(tester, slotTiles);

    await tester.tap(slotTiles.first);
    await tester.pump();

    // Phone is valid, but the name is left blank — the name field is
    // required, not optional, so submitting must still be blocked.
    final phoneField = find.widgetWithText(TextFormField, 'رقم هاتف المريض');
    await tester.enterText(phoneField, '01009998887');

    final submitButton = find.widgetWithText(FilledButton, 'تأكيد الحجز');
    await tester.ensureVisible(submitButton);
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('اسم المريض مطلوب'), findsOneWidget);
  });
}
