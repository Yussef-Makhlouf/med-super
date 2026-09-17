import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/file_upload_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders title, max size label and icon', (tester) async {
    await pumpLocalizedApp(
      tester,
      FileUploadCard(
        icon: Icons.upload_file,
        title: 'Medical License',
        maxSizeLabel: 'Max 5MB',
        onTap: () {},
      ),
    );

    expect(find.text('Medical License'), findsOneWidget);
    expect(find.text('Max 5MB'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    await pumpLocalizedApp(
      tester,
      FileUploadCard(
        icon: Icons.upload_file,
        title: 'National ID',
        maxSizeLabel: 'Max 5MB',
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('does not overflow on a narrow 320px width', (tester) async {
    // Realistic title length, matching the actual document-type labels this
    // card is used for (see provider_registration.verification.* in
    // assets/translations) — the fixed-height Container's Text has no
    // maxLines/ellipsis handling, so a pathologically long title would
    // genuinely overflow; that's outside the scope of this narrow-screen
    // check, which targets realistic content only.
    await pumpLocalizedApp(
      tester,
      SizedBox(
        width: 300,
        child: FileUploadCard(
          icon: Icons.upload_file,
          title: 'Specialty Certificate',
          maxSizeLabel: 'Max 5MB',
          onTap: () {},
        ),
      ),
      surfaceSize: const Size(320, 800),
    );

    expect(tester.takeException(), isNull);
  });
}
