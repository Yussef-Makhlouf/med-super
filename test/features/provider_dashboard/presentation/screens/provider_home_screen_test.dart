import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// The mock schedule-template seed (`_seedDoctorScheduleTemplates` in
/// `mock_responses.dart`) fixes weekday coverage: Saturday(6)/Sunday(7)/
/// Monday(1) at the Cairo branch, Wednesday(3) 10:00-14:00 at the
/// Alexandria branch. Tuesday/Thursday/Friday have no template at any
/// branch, i.e. a day off.
///
/// The week strip always shows Saturday..Friday of the week containing the
/// selected date, in fixed slots 0..6 (`providerCalendarDayTile-$index`).
/// Saturday is Dart weekday 6, so index = (weekday - 6) mod 7.
int _tileIndexForWeekday(int isoWeekday) => (isoWeekday - DateTime.saturday) % 7;

Future<void> _selectWeekday(WidgetTester tester, int isoWeekday) async {
  final key = Key('providerCalendarDayTile-${_tileIndexForWeekday(isoWeekday)}');
  await tester.tap(find.byKey(key));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets(
    'ProviderHomeScreen renders working hours for a day that has a template',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderHomeScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Monday has a template at the Cairo branch (09:00-17:00). The week
      // strip always shows the current week (Saturday..Friday), so Monday's
      // tile is visible without needing to page weeks.
      await _selectWeekday(tester, DateTime.monday);

      expect(find.textContaining('09:00 - 17:00'), findsOneWidget);
      expect(find.textContaining('عيادة النيل التخصصية'), findsWidgets);
    },
  );

  testWidgets(
    'ProviderHomeScreen renders the day-off state for a weekday with no template',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      await pumpLocalizedWidget(
        tester,
        const ProviderHomeScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Friday has no template at any branch.
      await _selectWeekday(tester, DateTime.friday);

      expect(find.text('يوم إجازة'), findsOneWidget);
    },
  );

  testWidgets(
    'ProviderHomeScreen layers real booked appointments on top of working hours',
    (tester) async {
      final storage = SecureStorageService(const FlutterSecureStorage());
      final dio = buildDioClient(storage: storage);

      // The mock seeds apt-1/apt-2 as CONFIRMED today at the Cairo branch.
      // Today's weekday must have a template there for them to be visible
      // through the home screen (Sat/Sun/Mon do; if today happens to fall on
      // a day off, fall back to asserting the empty-appointments copy
      // renders correctly on Wednesday at the Alexandria branch, which has a
      // template but none of the seeded appointments).
      final now = DateTime.now();
      final todayHasCairoTemplate = {
        DateTime.saturday,
        DateTime.sunday,
        DateTime.monday,
      }.contains(now.weekday);

      await pumpLocalizedWidget(
        tester,
        const ProviderHomeScreen(),
        overrides: [dioProvider.overrideWithValue(dio)],
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (todayHasCairoTemplate) {
        // Today is already selected by default, but the branch-scoped
        // appointments fetch starts after the template list first renders
        // this section — same extra I/O turn the Wednesday branch below
        // already accounts for.
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 2));
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('أحمد محمود'), findsOneWidget);
        expect(find.textContaining('سارة علي'), findsOneWidget);
      } else {
        await _selectWeekday(tester, DateTime.wednesday);
        // A second settle pass: the branch-scoped appointments fetch for
        // the newly selected day starts after the template list rebuilds
        // this section, so it needs its own real I/O turn beyond the one
        // `_selectWeekday` already gave it.
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 2));
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('10:00 - 14:00'), findsOneWidget);
        expect(
          find.text('لا توجد مواعيد محجوزة بعد لهذه الفترة.'),
          findsOneWidget,
        );
      }
    },
  );
}
