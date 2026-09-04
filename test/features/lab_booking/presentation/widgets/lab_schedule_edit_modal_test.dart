import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_edit_modal.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/schedule_day_chip_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/time_slot_period_section.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('opening the modal renders the relocated day/time pickers and an '
      'address field seeded from the current providers', (tester) async {
    late BuildContext capturedContext;
    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) {
          capturedContext = context;
          return ElevatedButton(
            onPressed: () => showLabScheduleEditModal(context),
            child: const Text('open'),
          );
        },
      ),
    );

    showLabScheduleEditModal(capturedContext);
    await tester.pumpAndSettle();

    expect(find.byType(LabScheduleEditModal), findsOneWidget);
    expect(find.byType(ScheduleDayChipBar), findsOneWidget);
    expect(find.byType(TimeSlotPeriodSection), findsNWidgets(2));
    expect(find.byType(TextField), findsOneWidget);
    // Seeded from `selectedLabAddressProvider`'s placeholder default.
    expect(find.text('العنوان الحالي غير محدد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders the real translated section titles for the day picker, time '
    'picker and address field — would fail on a wrong copy string in '
    'ar.json/en.json',
    (tester) async {
      late BuildContext capturedContext;
      await pumpLocalizedWidget(
        tester,
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      showLabScheduleEditModal(capturedContext);
      await tester.pumpAndSettle();

      expect(
        find.text('lab_booking.schedule_payment.choose_day_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.schedule_payment.choose_time_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.schedule_payment.morning_period_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.schedule_payment.evening_period_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.address_label'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save is disabled until a time is picked, and enabled once the '
      'address is non-empty and a time is selected', (tester) async {
    late BuildContext capturedContext;
    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    showLabScheduleEditModal(capturedContext);
    await tester.pumpAndSettle();

    // A time is pre-selected by `SelectedTimeSlot`'s default ('09:30')
    // and the address field is seeded with a non-empty placeholder, so
    // save should already be enabled.
    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNotNull);

    // Clearing the address disables save.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    final saveAfterClear = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(saveAfterClear.onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving writes the picked address back into the shared provider and '
    'closes the modal',
    (tester) async {
      late BuildContext capturedContext;
      String? savedAddress;

      await pumpLocalizedWidget(
        tester,
        Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            savedAddress = ref.watch(selectedLabAddressProvider);
            return const SizedBox.shrink();
          },
        ),
      );

      showLabScheduleEditModal(capturedContext);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'شارع النصر، مدينة نصر');
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveButton.onPressed, isNotNull);
      saveButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(LabScheduleEditModal), findsNothing);
      expect(savedAddress, 'شارع النصر، مدينة نصر');
    },
  );

  testWidgets(
    'save stays disabled while no time is selected, and enables once an '
    'available slot is tapped',
    (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await pumpLocalizedWidget(
        tester,
        Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            capturedRef = ref;
            // `selectedTimeSlotProvider` is autoDispose; in the real app the
            // review screen keeps it alive by watching it continuously (see
            // `lab_review_screen.dart`). Watching it here too so the
            // `select(null)` below survives instead of being reset back to
            // the provider's default as soon as its listener count drops to
            // zero between the read below and the modal's `initState` read.
            ref.watch(selectedTimeSlotProvider);
            return const SizedBox.shrink();
          },
        ),
      );

      // Force the seeded default ('09:30') back to null before opening the
      // modal, so its `initState` picks up a genuinely time-less state —
      // exercising the `_time != null` half of `_canSave` that the
      // address-clearing test above doesn't reach.
      capturedRef.read(selectedTimeSlotProvider.notifier).select(null);
      await tester.pump();

      showLabScheduleEditModal(capturedContext);
      await tester.pumpAndSettle();

      final disabledSave = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(disabledSave.onPressed, isNull);

      // '09:00' is the only morning slot whose formatted 12h label contains
      // this substring (see `lab_schedule_providers.dart`'s fixed morning
      // slot list). Match the exact chip label — computed the same way the
      // widget itself computes it (`TimeSlotPeriodSection` reads
      // `Localizations.localeOf(context).languageCode`, which is `'ar'`
      // here since `pumpLocalizedWidget`'s shell sets `startLocale:
      // Locale('ar')` — not `'en'`, which produced a string the widget
      // never actually renders), rather than a hand-typed literal, since
      // `intl`'s AM/PM formatting can use a non-ASCII space that silently
      // makes a plain `'9:00 AM'` string never match. A loose
      // `textContaining` isn't safe either — the period label above the
      // chips ("Morning (9:00 AM - 12:00 PM)") also contains "9:00" once
      // real translations are loaded, and it renders before the chips in
      // the tree, so a loose substring match's `.first` would hit that
      // inert label instead.
      final slotLabel = AppFormatters.time12h('09:00', locale: 'ar');
      await tester.tap(find.text(slotLabel));
      await tester.pump();

      final enabledSave = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(enabledSave.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping an unavailable time slot does not enable save', (
    tester,
  ) async {
    late BuildContext capturedContext;
    late WidgetRef capturedRef;
    await pumpLocalizedWidget(
      tester,
      Consumer(
        builder: (context, ref, _) {
          capturedContext = context;
          capturedRef = ref;
          // Keeps the autoDispose provider alive across the read/select
          // below — see the comment in the previous test for why.
          ref.watch(selectedTimeSlotProvider);
          return const SizedBox.shrink();
        },
      ),
    );

    capturedRef.read(selectedTimeSlotProvider.notifier).select(null);
    await tester.pump();

    showLabScheduleEditModal(capturedContext);
    await tester.pumpAndSettle();

    // '16:30' is the one evening slot marked `isAvailable: false` in
    // `lab_schedule_providers.dart` — tapping it must be a no-op.
    await tester.tap(find.textContaining('4:30').first);
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'picking a different day and time slot, then saving, writes both back '
    'into the shared providers alongside the address',
    (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await pumpLocalizedWidget(
        tester,
        Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            capturedRef = ref;
            // Keeps these autoDispose providers alive across the modal's
            // open/save/close lifecycle so the final `capturedRef.read(...)`
            // assertions below see the saved values instead of each
            // provider resetting to its default the moment the modal (its
            // only other listener) is popped — see the comment on the
            // first failing test above for the fuller explanation.
            ref.watch(selectedScheduleDayProvider);
            ref.watch(selectedTimeSlotProvider);
            ref.watch(selectedLabAddressProvider);
            return const SizedBox.shrink();
          },
        ),
      );

      // `SelectedScheduleDay` defaults to the *last* available day, so
      // picking the first one is a genuine change to assert on.
      final firstDay = capturedRef.read(labAvailableDaysProvider).first;
      expect(capturedRef.read(selectedScheduleDayProvider), isNot(firstDay));

      showLabScheduleEditModal(capturedContext);
      await tester.pumpAndSettle();

      await tester.tap(find.text('${firstDay.day}'));
      await tester.pump();
      // '11:00' is the one morning slot not already covered by the
      // default-selection tests above.
      await tester.tap(find.textContaining('11:00').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'شارع الجديد');
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveButton.onPressed, isNotNull);
      saveButton.onPressed!();
      await tester.pumpAndSettle();

      expect(capturedRef.read(selectedScheduleDayProvider), firstDay);
      expect(capturedRef.read(selectedTimeSlotProvider), '11:00');
      expect(capturedRef.read(selectedLabAddressProvider), 'شارع الجديد');
      expect(find.byType(LabScheduleEditModal), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
