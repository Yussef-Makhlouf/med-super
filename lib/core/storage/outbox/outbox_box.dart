import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:med_super/core/constants/hive_box_names.dart';
import 'pending_action.dart';

/// FIFO queue over the `pending_actions` Hive box.
/// Kept separate from TTL-evictable cache boxes — outbox is never evicted.
class OutboxBox {
  Box<String> get _box => Hive.box<String>(HiveBoxNames.outbox);

  List<PendingAction> readAll() {
    return _box.values
        .map((raw) {
          try {
            return PendingAction.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingAction>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> enqueue(PendingAction action) =>
      _box.put(action.id, jsonEncode(action.toJson()));

  Future<void> dequeue(String id) => _box.delete(id);

  Future<void> updateAttemptCount(PendingAction action) =>
      _box.put(action.id, jsonEncode(action.toJson()));

  bool get isEmpty => _box.isEmpty;
  int get length => _box.length;
}
