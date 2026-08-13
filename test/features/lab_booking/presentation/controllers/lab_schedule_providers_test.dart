import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('labAvailableDaysProvider', () {
    test('returns exactly 4 consecutive days starting today', () {
      final days = container.read(labAvailableDaysProvider);
      final today = DateTime.now();
      final expectedFirst = DateTime(today.year, today.month, today.day);

      expect(days, hasLength(4));
      expect(days.first, expectedFirst);
      for (var i = 1; i < days.length; i++) {
        expect(days[i].difference(days[i - 1]).inDays, 1);
      }
    });
  });

  group('labTimeSlotsByPeriodProvider', () {
    test('has a morning and an evening period, each non-empty', () {
      final slots = container.read(labTimeSlotsByPeriodProvider);

      expect(slots.keys, containsAll(['morning', 'evening']));
      expect(slots['morning'], isNotEmpty);
      expect(slots['evening'], isNotEmpty);
    });

    test('every morning slot is available', () {
      final slots = container.read(labTimeSlotsByPeriodProvider);
      expect(slots['morning']!.every((s) => s.isAvailable), isTrue);
    });

    test('at least one evening slot is unavailable, matching the design', () {
      final slots = container.read(labTimeSlotsByPeriodProvider);
      expect(slots['evening']!.any((s) => !s.isAvailable), isTrue);
    });
  });

  group('selectedScheduleDayProvider', () {
    test('defaults to the last available day', () {
      final days = container.read(labAvailableDaysProvider);
      final selected = container.read(selectedScheduleDayProvider);
      expect(selected, days.last);
    });

    test('select updates the state', () {
      final days = container.read(labAvailableDaysProvider);
      container.read(selectedScheduleDayProvider.notifier).select(days.first);
      expect(container.read(selectedScheduleDayProvider), days.first);
    });
  });

  group('selectedTimeSlotProvider', () {
    test('defaults to "09:30"', () {
      expect(container.read(selectedTimeSlotProvider), '09:30');
    });

    test('select updates the state', () {
      container.read(selectedTimeSlotProvider.notifier).select('11:00');
      expect(container.read(selectedTimeSlotProvider), '11:00');
    });

    test('select can clear back to null', () {
      container.read(selectedTimeSlotProvider.notifier).select(null);
      expect(container.read(selectedTimeSlotProvider), isNull);
    });
  });

  group('selectedPaymentMethodProvider', () {
    test('defaults to onlinePayment', () {
      expect(
        container.read(selectedPaymentMethodProvider),
        LabPaymentMethod.onlinePayment,
      );
    });

    test('select updates the state', () {
      container
          .read(selectedPaymentMethodProvider.notifier)
          .select(LabPaymentMethod.payAtService);
      expect(
        container.read(selectedPaymentMethodProvider),
        LabPaymentMethod.payAtService,
      );
    });
  });

  group('selectedLabAddressProvider', () {
    test('has a non-empty placeholder default', () {
      expect(container.read(selectedLabAddressProvider), isNotEmpty);
    });

    test('select updates the state', () {
      container.read(selectedLabAddressProvider.notifier).select('123 Main St');
      expect(container.read(selectedLabAddressProvider), '123 Main St');
    });
  });
}
