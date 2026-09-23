import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// The mock schedule-template seed (`_seedDoctorScheduleTemplates` in
/// `mock_responses.dart`) fixes weekday coverage: Saturday(6)/Sunday(7)/
/// Monday(1) at the Cairo branch, Wednesday(3) at the Alexandria branch.
/// Tuesday/Thursday/Friday have no template at any branch, i.e. a day off.
///
/// Only the Cairo branch is VERIFIED/ACTIVE (`isAcceptingBookings`), so the
/// home screen renders a single-branch timeline (no tabs) for it: that
/// day's real booked appointments merged with its real open slots.
///
/// The week strip always shows Saturday..Friday of the week containing the
/// selected date, in fixed slots 0..6 (`providerCalendarDayTile-$index`).
/// Saturday is Dart weekday 6, so index = (weekday - 6) mod 7.
int _tileIndexForWeekday(int isoWeekday) => (isoWeekday - DateTime.saturday) % 7;

Finder _dayTile(int isoWeekday) =>
    find.byKey(Key('providerCalendarDayTile-${_tileIndexForWeekday(isoWeekday)}'));

/// The small "working day" dot under a day tile's date — filled when the
/// doctor has a schedule template for that weekday, transparent otherwise.
bool _hasWorkingDayDot(WidgetTester tester, int isoWeekday) {
  final dots = tester.widgetList<Container>(
    find.descendant(
      of: _dayTile(isoWeekday),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    ),
  );
  expect(dots, hasLength(1));
  final color = (dots.single.decoration! as BoxDecoration).color;
  return color != null && color != Colors.transparent;
}

/// Open-slot rows on the timeline are labelled "متاح" (bookable) or
/// "انتهى الوقت" (already past) depending on the current time.
Finder get _openSlotRows => find.byWidgetPredicate(
  (w) => w is Text && (w.data == 'متاح' || w.data == 'انتهى الوقت'),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _pumpHome(
  WidgetTester tester, {
  bool noOpenSlots = false,
}) async {
  final storage = SecureStorageService(const FlutterSecureStorage());
  final dio = buildDioClient(storage: storage);

  await pumpLocalizedWidget(
    tester,
    const ProviderHomeScreen(),
    overrides: [
      dioProvider.overrideWithValue(dio),
      // The mock `/slots` endpoint generates 09:00-16:30 slots for every
      // day regardless of templates; the real backend only generates slots
      // from a schedule template, so a template-less day has none.
      if (noOpenSlots)
        doctorOpenSlotsProvider.overrideWith((ref, _) async => <DoctorSlot>[]),
    ],
  );

  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _selectWeekday(WidgetTester tester, int isoWeekday) async {
  await tester.tap(_dayTile(isoWeekday));
  await _settle(tester);
  // The branch-scoped appointments/slots fetches for the newly selected day
  // start after the clinics list rebuilds this section, so give them their
  // own real I/O turn.
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets(
    'ProviderHomeScreen renders working hours for a day that has a template',
    (tester) async {
      await _pumpHome(tester);
      await _settle(tester);

      // Monday has a template at the Cairo branch; Friday has none.
      expect(_hasWorkingDayDot(tester, DateTime.monday), isTrue);
      expect(_hasWorkingDayDot(tester, DateTime.friday), isFalse);

      await _selectWeekday(tester, DateTime.monday);

      // The day's open slots are laid out as timeline rows, not the
      // day-off empty state.
      expect(_openSlotRows, findsWidgets);
      expect(find.text('يوم إجازة'), findsNothing);
    },
  );

  testWidgets(
    'ProviderHomeScreen renders the day-off state for a weekday with no template',
    (tester) async {
      await _pumpHome(tester, noOpenSlots: true);
      await _settle(tester);

      // Page to next week first: the mock seeds appointments from yesterday
      // through today+2, which can fall on this week's Friday. Next week's
      // Friday is always at least 7 days out, and Friday has no template.
      // (In the RTL header, chevron_left is "next week".)
      await tester.tap(find.byIcon(Icons.chevron_left));
      await _settle(tester);
      await _selectWeekday(tester, DateTime.friday);

      expect(_hasWorkingDayDot(tester, DateTime.friday), isFalse);
      expect(find.text('يوم إجازة'), findsOneWidget);
      expect(_openSlotRows, findsNothing);
    },
  );

  testWidgets(
    'ProviderHomeScreen layers real booked appointments on top of working hours',
    (tester) async {
      // The mock seeds apt-1/apt-2 as CONFIRMED today at the Cairo branch.
      // Today is selected by default.
      await _pumpHome(tester);
      await _settle(tester);
      await _settle(tester);

      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);
      // ...merged into the same timeline as the day's open slots.
      expect(_openSlotRows, findsWidgets);
    },
  );
}
