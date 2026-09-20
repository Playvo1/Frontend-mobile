import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the Sanctum bearer token lives. Abstract so services can be unit
/// tested with an in-memory fake (Guidelines 2.5) and so the storage
/// backend can change without touching callers (Dependency Inversion).
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Keychain (iOS) / EncryptedSharedPreferences (Android) implementation.
/// The token is a credential, so it never goes into plain SharedPreferences
/// (Guidelines 2.4).
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const String _key = 'playvo_auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// In-memory implementation for tests.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
