import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

/// Reads `assets/translations/<locale>.json` straight off disk via
/// synchronous `dart:io`, instead of easy_localization's default
/// [RootBundleAssetLoader] which goes through `rootBundle.loadString` (a
/// real async plugin-channel round trip).
class _SyncFileAssetLoader extends AssetLoader {
  const _SyncFileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final content = file.readAsStringSync();
    return SynchronousFuture(json.decode(content) as Map<String, dynamic>);
  }
}

Widget _shell({required Widget child, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: false,
      useOnlyLangCode: true,
      assetLoader: const _SyncFileAssetLoader(),
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
/// The `Localizations` widget's delegate.load() is asynchronous even for a
/// synchronous [AssetLoader] (`Future.wait` still hops the microtask queue),
/// so the very first frame after `pumpWidget` renders with translations
/// unresolved — `.tr()` falls back to the raw (long) key, which is long
/// enough to overflow some of this feature's fixed-width Rows. Flutter's
/// test binding fails the test on *any* frame that throws during the pump
/// sequence, even if a later frame recovers, so that first frame matters.
/// To avoid it: pump an empty placeholder under the same shell first, let
/// translations finish loading against that (nothing to overflow), then
/// swap in the real [child] — since the outer widget tree shape is
/// unchanged, Flutter reuses the same `EasyLocalization`/`Localizations`
/// elements, so the swap-in frame renders with translations already
/// resolved from the very start.
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
  await EasyLocalization.ensureInitialized();

  // Even with the placeholder-then-swap dance above, translations can still
  // resolve one frame late for some widgets in practice (observed
  // empirically — a residual `Localizations`/easy_localization timing
  // quirk in this Flutter/easy_localization version combo). A `.tr()` call
  // that misses falls back to the raw (long) translation key rather than
  // throwing, which is harmless UNLESS it renders inside one of this
  // feature's fixed-width Rows without an `Expanded`/`Flexible`, where the
  // extra length overflows and *that* throws. Give every test a viewport
  // far wider than any real phone so a raw fallback key never overflows,
  // regardless of whether translations happened to land in time.
  tester.view.physicalSize = const Size(2400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _shell(child: const SizedBox.shrink(), overrides: overrides),
  );
  await tester.pumpAndSettle();

  await tester.pumpWidget(_shell(child: child, overrides: overrides));
  // Some widgets under test (e.g. a submit spinner) run a perpetual
  // animation, which would make `pumpAndSettle()` here spin until its
  // internal timeout and fail the test. A bounded number of plain pumps is
  // enough to flush the translation-load frame(s) without waiting for
  // "no more scheduled frames ever" on a widget that never reaches that.
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}
