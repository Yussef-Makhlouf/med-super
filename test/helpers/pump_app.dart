import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [child] wrapped in a real [EasyLocalization] + [MaterialApp], matching
/// how the app itself bootstraps localization (see lib/bootstrap.dart), so
/// widgets using `.tr()` resolve real strings from assets/translations.
Future<void> pumpLocalizedApp(
  WidgetTester tester,
  Widget child, {
  Size surfaceSize = const Size(400, 800),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  // easy_localization loads its JSON translation files from disk via real
  // (non-fake-clock) dart:io/asset-bundle I/O. `tester.pump()`/pumpAndSettle
  // alone only flush the fake frame clock and never drive that real I/O to
  // completion, so this whole sequence must run inside `tester.runAsync` or
  // it hangs forever waiting on the asset load.
  // easy_localization persists the chosen locale via shared_preferences,
  // which needs its platform-channel mock seeded before ensureInitialized()
  // runs, or it throws MissingPluginException in a plain `flutter test`.
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    // First pump builds EasyLocalization's FutureBuilder for asset loading.
    await tester.pumpAndSettle();
  });
}

/// Pumps [child] in a plain [MaterialApp]/[Scaffold] — for widgets that do
/// not depend on easy_localization.
Future<void> pumpPlainApp(
  WidgetTester tester,
  Widget child, {
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
  }
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}
