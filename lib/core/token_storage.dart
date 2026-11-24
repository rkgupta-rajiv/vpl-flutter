import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Sanctum bearer token in the platform keystore / keychain.
class TokenStorage {
  static const _key = 'vpl_auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);
}
