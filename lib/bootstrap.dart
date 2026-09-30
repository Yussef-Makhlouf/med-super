import 'dart:async';
import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:med_super/core/config/app_config.dart';
import 'package:med_super/core/notifications/fcm_service.dart';
import 'package:med_super/core/storage/hive_service.dart';
import 'package:med_super/firebase_options.dart';

Future<void> bootstrap(Widget Function() appBuilder) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_BootstrapGate(appBuilder: appBuilder));
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate({required this.appBuilder});

  final Widget Function() appBuilder;

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  String _stage = 'جارٍ تجهيز التطبيق…';
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _stage = 'جارٍ تهيئة التطبيق…';
      _error = null;
      _ready = false;
    });

    try {
      AppConfig.instance.validateForStartup();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await EasyLocalization.ensureInitialized();

      if (mounted) setState(() => _stage = 'جارٍ تجهيز التخزين الآمن…');
      await HiveService.init(const FlutterSecureStorage());

      if (mounted) setState(() => _stage = 'جارٍ الاتصال بخدمات الإشعارات…');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (error, stackTrace) {
        debugPrint('Firebase init skipped: $error\n$stackTrace');
      }

      if (mounted) setState(() => _ready = true);
    } catch (error, stackTrace) {
      debugPrint('App startup failed: $error\n$stackTrace');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: ProviderScope(child: widget.appBuilder()),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2457D6)),
      home: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF163B9E),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.health_and_safety,
                      size: 72,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'MedSuper',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error == null) ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _stage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ] else ...[
                      const Text(
                        'تعذر تهيئة أحد مكونات التطبيق. أعد المحاولة، وإذا استمر العطل أرسل لقطة شاشة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => unawaited(_initialize()),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
