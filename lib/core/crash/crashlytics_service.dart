import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:med_super/core/error/failure.dart';

/// Reports non-fatal errors per the §6 policy:
/// ValidationFailure / NetworkFailure / ConflictFailure are expected outcomes
/// and are NOT sent. UnknownFailure and 5xx ServerFailure are.
class CrashlyticsService {
  const CrashlyticsService(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> init() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = _crashlytics.recordFlutterFatalError;
    } catch (e) {
      if (kDebugMode) debugPrint('CrashlyticsService: init skipped — $e');
    }
  }

  void recordFailure(Failure failure) {
    switch (failure) {
      case ValidationFailure() || NetworkFailure() || ConflictFailure():
        // Expected business outcomes — not noise.
        return;
      case ServerFailure(:final statusCode, :final code, :final message):
        if (statusCode < 500) return;
        _crashlytics.recordError(
          '$code: $message',
          null,
          reason: 'ServerFailure $statusCode',
          fatal: false,
        );
      case UnknownFailure(:final error, :final stackTrace):
        _crashlytics.recordError(error, stackTrace, fatal: false);
      case AuthFailure() || CacheFailure():
        break;
    }
  }
}
