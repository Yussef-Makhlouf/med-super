import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the same EasyLocalization + MaterialApp shell as
/// `bootstrap.dart`/`app.dart`, using easy_localization's default
/// [RootBundleAssetLoader] (real `rootBundle.loadString` calls) rather than
/// a custom synchronous loader — see the doc comment on
/// [pumpLocalizedWidget] for why a synchronous loader doesn't actually avoid
/// needing real async I/O here.
Widget _shell({required Widget child, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: false,
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(body: child),
          );
        },
      ),
    ),
  );
}

/// Pumps [child] wrapped in the same EasyLocalization + MaterialApp shell
/// that `bootstrap.dart`/`app.dart` use in the real app, so widgets calling
/// `.tr()` resolve real strings from `assets/translations/*.json` instead of
/// throwing or falling back to the raw key.
///
/// easy_localization's default asset loader reads translation files via
/// `rootBundle.loadString`, which is real (non-fake-clock) I/O —
/// `tester.pump()`/`pumpAndSettle()` alone only flush the fake frame clock
/// and never drive that real I/O to completion, so the whole pump sequence
/// must run inside `tester.runAsync` or `.tr()` permanently falls back to
/// the raw key (logged as "Localization key [...] not found") no matter how
/// many frames are pumped afterwards. A previous version of this helper
/// tried to dodge that by supplying a synchronous [AssetLoader] over
/// `dart:io` instead of `runAsync`, on the theory that a `SynchronousFuture`
/// wouldn't need a real event-loop turn to resolve — empirically that did
/// not work (translations still never resolved), so this uses the same
/// real-loader-plus-`runAsync` approach as `test/helpers/pump_app.dart`.
///
/// [overrides] lets tests stub out repository/usecase providers via
/// `ProviderContainer`-style overrides while still pumping a real widget
/// tree (needed for screens/widgets that read Riverpod providers).
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  // easy_localization persists the chosen locale via SharedPreferences;
  // without a mock, SharedPreferences.getInstance() never resolves under
  // flutter_test (no platform-channel implementation registered), which
  // hangs pumpAndSettle forever. Seed an in-memory mock instead.
  SharedPreferences.setMockInitialValues({});

  // Give every test a viewport far wider than any real phone so a raw
  // fallback key (long) never overflows one of this feature's fixed-width
  // Rows in the unlikely event a `.tr()` call still misses.
  tester.view.physicalSize = const Size(2400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(_shell(child: child, overrides: overrides));
    // Not `pumpAndSettle()`: some widgets under test (e.g. a submit
    // spinner) run a perpetual animation, which would make it spin until
    // its internal timeout and fail the test. A bounded number of pumps
    // (each a real async round trip inside `runAsync`) is enough to flush
    // the translation-load future without waiting for "no more scheduled
    // frames ever" on a widget that never reaches that.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  });
}
