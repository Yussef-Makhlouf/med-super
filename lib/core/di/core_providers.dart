import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/config/app_config.dart';
import 'package:med_super/core/crash/crashlytics_service.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/network/network_info.dart';
import 'package:med_super/core/notifications/fcm_service.dart';
import 'package:med_super/core/notifications/local_notification_service.dart';
import 'package:med_super/core/notifications/notification_priority_router.dart';
import 'package:med_super/core/storage/hive_service.dart';
import 'package:med_super/core/storage/outbox/outbox_box.dart';
import 'package:med_super/core/storage/outbox/sync_service.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

part 'core_providers.g.dart';

// ── Config ───────────────────────────────────────────────────────────────────

@riverpod
AppConfig appConfig(Ref ref) => AppConfig.instance;

// ── Storage ──────────────────────────────────────────────────────────────────

@riverpod
FlutterSecureStorage flutterSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

@riverpod
SecureStorageService secureStorage(Ref ref) =>
    SecureStorageService(ref.watch(flutterSecureStorageProvider));

@riverpod
HiveService hiveService(Ref ref) => HiveService.instance;

@riverpod
OutboxBox outboxBox(Ref ref) => OutboxBox();

// ── Network ──────────────────────────────────────────────────────────────────

@riverpod
Connectivity connectivity(Ref ref) => Connectivity();

@riverpod
NetworkInfo networkInfo(Ref ref) =>
    NetworkInfo(ref.watch(connectivityProvider));

@riverpod
Dio dio(Ref ref) =>
    buildDioClient(storage: ref.watch(secureStorageProvider));

// ── Services ─────────────────────────────────────────────────────────────────

@riverpod
CrashlyticsService crashlyticsService(Ref ref) =>
    CrashlyticsService(FirebaseCrashlytics.instance);

@riverpod
FcmService fcmService(Ref ref) => FcmService(FirebaseMessaging.instance);

@riverpod
LocalNotificationService localNotificationService(Ref ref) =>
    LocalNotificationService();

@riverpod
NotificationPriorityRouter notificationPriorityRouter(Ref ref) =>
    NotificationPriorityRouter();

@riverpod
SyncService syncService(Ref ref) => SyncService(
      networkInfo: ref.watch(networkInfoProvider),
      outbox: ref.watch(outboxBoxProvider),
    );
