import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_branch_repository.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/pharmacy_branch_providers.dart';
import 'package:med_super/features/provider_profile/presentation/screens/pharmacy_branch_details_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../helpers/pump_localized_widget.dart';

class _MockPharmacyBranchRepository extends Mock
    implements PharmacyBranchRepository {}

const _branch = PharmacyBranch(
  id: 'branch-1',
  pharmacyId: 'pharmacy-1',
  pharmacyName: 'Al Ezaby Pharmacy',
  phone: '+201234567890',
  ianaTimezone: 'Africa/Cairo',
  deliveryCapable: true,
  status: 'VERIFIED',
  address: PharmacyBranchAddress(
    line1: '12 Tahrir St',
    city: 'Cairo',
    regionCode: 'CAI',
    countryCode: 'EG',
  ),
);

/// A bounded stand-in for `tester.pumpAndSettle()` — mirrors
/// `lab_select_partner_screen_test.dart`'s `_settle` helper (see its doc
/// comment): safe to use even while a perpetually-animating
/// `CircularProgressIndicator` is still in the tree.
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
});

void main() {
  late _MockPharmacyBranchRepository repository;

  setUp(() {
    repository = _MockPharmacyBranchRepository();
  });

  List<Override> overrides() => [
    pharmacyBranchRepositoryProvider.overrideWithValue(repository),
  ];

  testWidgets('shows a loading spinner before the branch resolves', (
    tester,
  ) async {
    final completer = Completer<Result<PharmacyBranch>>();
    when(
      () => repository.getPharmacyBranch(any()),
    ).thenAnswer((_) => completer.future);

    await pumpLocalizedWidget(
      tester,
      const PharmacyBranchDetailsScreen(branchId: 'branch-1'),
      overrides: overrides(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Al Ezaby Pharmacy'), findsNothing);

    completer.complete(const Result.ok(_branch));
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders branch details once the data resolves', (
    tester,
  ) async {
    when(
      () => repository.getPharmacyBranch(any()),
    ).thenAnswer((_) async => const Result.ok(_branch));

    await pumpLocalizedWidget(
      tester,
      const PharmacyBranchDetailsScreen(branchId: 'branch-1'),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.text('Al Ezaby Pharmacy'), findsOneWidget);
    // The widget wraps the phone in `AppFormatters.ltrIsolate` (U+2066/
    // U+2069 isolate marks) so it renders left-to-right inside the
    // Arabic-RTL shell `pumpLocalizedWidget` uses — a plain phone string
    // never matches the actual `Text` widget.
    expect(find.text(AppFormatters.ltrIsolate('+201234567890')), findsOneWidget);
    expect(find.text('Africa/Cairo'), findsOneWidget);
    expect(find.text('12 Tahrir St'), findsOneWidget);
    expect(find.text('Cairo, CAI'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hides the verified badge and delivery chip when not applicable',
    (tester) async {
      when(() => repository.getPharmacyBranch(any())).thenAnswer(
        (_) async => const Result.ok(
          PharmacyBranch(
            id: 'branch-2',
            pharmacyId: 'pharmacy-2',
            pharmacyName: 'Local Pharmacy',
            phone: '+201111111111',
            ianaTimezone: 'Africa/Cairo',
            deliveryCapable: false,
            status: 'PENDING',
            address: PharmacyBranchAddress(
              line1: '5 Nile St',
              city: 'Giza',
              regionCode: 'GIZ',
              countryCode: 'EG',
            ),
          ),
        ),
      );

      await pumpLocalizedWidget(
        tester,
        const PharmacyBranchDetailsScreen(branchId: 'branch-2'),
        overrides: overrides(),
      );
      await _settle(tester);

      expect(find.text('Local Pharmacy'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.byIcon(Icons.delivery_dining_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders an error view instead of crashing when the fetch fails', (
    tester,
  ) async {
    when(
      () => repository.getPharmacyBranch(any()),
    ).thenAnswer((_) async => const Result.err(Failure.network()));

    await pumpLocalizedWidget(
      tester,
      const PharmacyBranchDetailsScreen(branchId: 'branch-1'),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.text('Al Ezaby Pharmacy'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
