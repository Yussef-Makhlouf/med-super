import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:med_super/core/constants/storage_keys.dart';

/// Wraps flutter_secure_storage. Never stores PHI — tokens and flags only.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> get accessToken =>
      _storage.read(key: StorageKeys.accessToken);

  Future<String?> get refreshToken =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<bool> get hasSession async => (await accessToken) != null;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }
}
