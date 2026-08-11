import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:med_super/core/constants/hive_box_names.dart';

/// Box lifecycle, HiveAesCipher encryption setup, and a generic JSON-backed
/// CacheStore for typed feature caches.
class HiveService {
  HiveService._(this._storage);

  static HiveService? _instance;
  static HiveService get instance {
    assert(_instance != null, 'HiveService.init() not called');
    return _instance!;
  }

  final FlutterSecureStorage _storage;

  static const _cipherKey = 'hive_cipher_key';

  static Future<HiveService> init(FlutterSecureStorage storage) async {
    await Hive.initFlutter();
    _instance = HiveService._(storage);
    await _instance!._openBoxes();
    return _instance!;
  }

  Future<void> _openBoxes() async {
    final cipher = await _cipher();
    await Future.wait([
      Hive.openBox<String>(HiveBoxNames.settings, encryptionCipher: cipher),
      Hive.openBox<String>(
        HiveBoxNames.doctorSearchCache,
        encryptionCipher: cipher,
      ),
      Hive.openBox<String>(
        HiveBoxNames.appointmentCache,
        encryptionCipher: cipher,
      ),
      Hive.openBox<String>(HiveBoxNames.outbox, encryptionCipher: cipher),
      Hive.openBox<String>(
        HiveBoxNames.providerRegistrationDraft,
        encryptionCipher: cipher,
      ),
    ]);
  }

  Future<HiveAesCipher> _cipher() async {
    var keyHex = await _storage.read(key: _cipherKey);
    if (keyHex == null) {
      final key = Hive.generateSecureKey();
      keyHex = base64Encode(key);
      await _storage.write(key: _cipherKey, value: keyHex);
    }
    return HiveAesCipher(base64Decode(keyHex));
  }

  Box<String> get settingsBox => Hive.box<String>(HiveBoxNames.settings);
  Box<String> get outboxBox => Hive.box<String>(HiveBoxNames.outbox);
  Box<String> get searchCacheBox =>
      Hive.box<String>(HiveBoxNames.doctorSearchCache);
  Box<String> get appointmentCacheBox =>
      Hive.box<String>(HiveBoxNames.appointmentCache);
  Box<String> get providerRegistrationDraftBox =>
      Hive.box<String>(HiveBoxNames.providerRegistrationDraft);
}

/// Generic JSON-backed cache store. Stores entities as JSON strings in Hive.
class CacheStore<T> {
  CacheStore({
    required this._box,
    required this._fromJson,
    required this._toJson,
  });

  final Box<String> _box;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;

  T? read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, T value) =>
      _box.put(key, jsonEncode(_toJson(value)));

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}
