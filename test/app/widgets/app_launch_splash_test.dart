import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/app/widgets/app_launch_splash.dart';

import '../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('uses the current MedSuper brand mark on the launch splash', (
    tester,
  ) async {
    const splash = AppLaunchSplash(child: SizedBox.expand());
    await pumpLocalizedWidget(tester, splash);

    expect(find.byKey(const Key('medsuper-app-splash-mark')), findsOneWidget);
  });
}
