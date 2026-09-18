import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/review_section_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders title, icon and every row label/value', (tester) async {
    await pumpPlainApp(
      tester,
      ReviewSectionCard(
        title: 'Basic Info',
        icon: Icons.person,
        rows: const [ReviewRow('Name', 'Dr. Sara'), ReviewRow('Degree', 'MD')],
        onEdit: () {},
      ),
    );

    expect(find.text('Basic Info'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Dr. Sara'), findsOneWidget);
    expect(find.text('Degree'), findsOneWidget);
    expect(find.text('MD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes onEdit when the edit button is tapped', (tester) async {
    var edited = false;
    await pumpPlainApp(
      tester,
      ReviewSectionCard(
        title: 'Clinic',
        icon: Icons.local_hospital,
        rows: const [],
        onEdit: () => edited = true,
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(edited, isTrue);
  });

  testWidgets('renders trailing widget when provided', (tester) async {
    await pumpPlainApp(
      tester,
      ReviewSectionCard(
        title: 'Clinic',
        icon: Icons.local_hospital,
        rows: const [],
        onEdit: () {},
        trailing: const Text('trailing-marker'),
      ),
    );

    expect(find.text('trailing-marker'), findsOneWidget);
  });

  testWidgets('renders with an empty rows list without throwing', (
    tester,
  ) async {
    await pumpPlainApp(
      tester,
      ReviewSectionCard(
        title: 'Empty',
        icon: Icons.info,
        rows: const [],
        onEdit: () {},
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on a narrow 320px width with many rows', (
    tester,
  ) async {
    await pumpPlainApp(
      tester,
      ReviewSectionCard(
        title: 'Very Long Section Title That Could Wrap Or Overflow',
        icon: Icons.medical_information,
        rows: const [
          ReviewRow('Clinic name', 'A very long clinic name value here'),
          ReviewRow('Address', 'A very long clinic address value indeed'),
        ],
        onEdit: () {},
      ),
      surfaceSize: const Size(320, 900),
    );

    expect(tester.takeException(), isNull);
  });
}
