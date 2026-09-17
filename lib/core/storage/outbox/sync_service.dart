import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:med_super/core/network/network_info.dart';
import 'outbox_box.dart';
import 'pending_action.dart';

typedef ActionHandler = Future<bool> Function(PendingAction action);

/// Replays queued [PendingAction]s on reconnect, in enqueue order.
/// Handlers are registered per action type; unrecognised types are skipped.
class SyncService {
  SyncService({required this._networkInfo, required this._outbox});

  final NetworkInfo _networkInfo;
  final OutboxBox _outbox;
  final Map<String, ActionHandler> _handlers = {};

  StreamSubscription<bool>? _sub;

  void registerHandler(String type, ActionHandler handler) {
    _handlers[type] = handler;
  }

  void start() {
    _sub = _networkInfo.onConnectivityChanged.listen((isOnline) {
      if (isOnline) _replay();
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _replay() async {
    if (_outbox.isEmpty) return;

    final actions = _outbox.readAll();
    for (final action in actions) {
      final handler = _handlers[action.type];
      if (handler == null) continue;

      try {
        final success = await handler(action);
        if (success) {
          await _outbox.dequeue(action.id);
        } else {
          await _outbox.updateAttemptCount(
            action.copyWith(attemptCount: action.attemptCount + 1),
          );
        }
      } catch (e) {
        if (kDebugMode)
          debugPrint('SyncService: error replaying ${action.id}: $e');
      }
    }
  }
}
