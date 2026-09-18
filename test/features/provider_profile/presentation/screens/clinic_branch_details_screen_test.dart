import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_branch_repository.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/clinic_branch_providers.dart';
import 'package:med_super/features/provider_profile/presentation/screens/clinic_branch_details_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:solar_icons/solar_icons.dart';

import '../../../../helpers/pump_localized_widget.dart';

class _MockClinicBranchRepository extends Mock
    implements ClinicBranchRepository {}

const _branchId = 'branch-1';

const _branch = ClinicBranch(
  id: _branchId,
  clinicId: 'clinic-1',
  phone: '+201234567890',
  ianaTimezone: 'Africa/Cairo',
  status: ClinicBranchStatus.verified,
  address: ClinicBranchAddress(
    line1: '12 Tahrir St',
    city: 'Cairo',
    regionCode: 'CAI',
    countryCode: 'EG',
  ),
  clinic: ClinicSummary(
    id: 'clinic-1',
    legalName: 'Nile Medical Group LLC',
    brandName: 'Nile Medical',
    status: ClinicBranchStatus.verified,
  ),
);

/// A bounded stand-in for `tester.pumpAndSettle()` for use whenever a
/// `CircularProgressIndicator` might still be in the tree — mirrors
/// `lab_select_partner_screen_test.dart`'s `_settle` helper.
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
});

void main() {
  late _MockClinicBranchRepository repository;

  setUp(() {
    repository = _MockClinicBranchRepository();
  });

  List<Override> overrides() => [
    clinicBranchRepositoryProvider.overrideWithValue(repository),
  ];

  testWidgets('shows a loading spinner before the branch resolves', (
    tester,
  ) async {
    final completer = Completer<Result<ClinicBranch>>();
    when(
      () => repository.getClinicBranch(_branchId),
    ).thenAnswer((_) => completer.future);

    await pumpLocalizedWidget(
      tester,
      const ClinicBranchDetailsScreen(branchId: _branchId),
      overrides: overrides(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nile Medical'), findsNothing);

    completer.complete(const Result.ok(_branch));
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the branch data once loaded', (tester) async {
    when(
      () => repository.getClinicBranch(_branchId),
    ).thenAnswer((_) async => const Result.ok(_branch));

    await pumpLocalizedWidget(
      tester,
      const ClinicBranchDetailsScreen(branchId: _branchId),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.text('Nile Medical'), findsOneWidget);
    expect(find.text('Nile Medical Group LLC'), findsOneWidget);
    expect(find.text('12 Tahrir St'), findsOneWidget);
    expect(find.text('Cairo, CAI'), findsOneWidget);
    // The widget wraps the phone in `AppFormatters.ltrIsolate` (U+2066/
    // U+2069 isolate marks) so it renders left-to-right inside the
    // Arabic-RTL shell `pumpLocalizedWidget` uses — a plain phone string
    // never matches the actual `Text` widget.
    expect(find.text(AppFormatters.ltrIsolate('+201234567890')), findsOneWidget);
    expect(find.text('Africa/Cairo'), findsOneWidget);
    expect(find.byIcon(SolarIconsBold.shieldCheck), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an error view instead of crashing when it fails', (
    tester,
  ) async {
    when(
      () => repository.getClinicBranch(_branchId),
    ).thenAnswer((_) async => const Result.err(Failure.network()));

    await pumpLocalizedWidget(
      tester,
      const ClinicBranchDetailsScreen(branchId: _branchId),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.text('Nile Medical'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
