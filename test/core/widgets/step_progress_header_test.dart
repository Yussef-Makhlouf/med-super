import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';

import '../../helpers/pump_app.dart';

void main() {
  const labels = ['Basic Info', 'Verification', 'Clinic Schedule', 'Review'];

  testWidgets('renders every step label', (tester) async {
    await pumpPlainApp(
      tester,
      StepProgressHeader(
        stepLabels: labels,
        currentStep: 0,
        accentColor: Colors.teal,
      ),
    );

    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a check icon for completed steps and numbers otherwise', (
    tester,
  ) async {
    await pumpPlainApp(
      tester,
      StepProgressHeader(
        stepLabels: labels,
        currentStep: 2,
        accentColor: Colors.teal,
      ),
    );

    // Steps 0 and 1 are done (< currentStep) -> check icons.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    // Step 2 is active, step 3 is inactive -> numeric labels remain.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('currentStep 0 shows no check icons and no progress fill', (
    tester,
  ) async {
    await pumpPlainApp(
      tester,
      StepProgressHeader(
        stepLabels: labels,
        currentStep: 0,
        accentColor: Colors.teal,
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('works correctly with a single step (avoids divide-by-zero)', (
    tester,
  ) async {
    await pumpPlainApp(
      tester,
      StepProgressHeader(
        stepLabels: const ['Only step'],
        currentStep: 0,
        accentColor: Colors.teal,
      ),
    );

    expect(find.text('Only step'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'does not overflow with 4 steps on a narrow ${width}px screen',
      (tester) async {
        await pumpPlainApp(
          tester,
          StepProgressHeader(
            stepLabels: labels,
            currentStep: 1,
            accentColor: Colors.teal,
          ),
          surfaceSize: Size(width, 200),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'does not overflow with long labels on a narrow ${width}px screen',
      (tester) async {
        await pumpPlainApp(
          tester,
          StepProgressHeader(
            stepLabels: const [
              'A very long first step label indeed',
              'Another quite long second step label',
              'Third step label also fairly long here',
              'Fourth and final quite long step label',
            ],
            currentStep: 3,
            accentColor: Colors.teal,
          ),
          surfaceSize: Size(width, 200),
        );

        expect(tester.takeException(), isNull);
      },
    );
  }
}
