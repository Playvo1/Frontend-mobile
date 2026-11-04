import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the Sanctum bearer token lives. Abstract so services can be unit
/// tested with an in-memory fake (Guidelines 2.5) and so the storage
/// backend can change without touching callers (Dependency Inversion).
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);

  /// The signed-in account as JSON, kept beside the token.
  ///
  /// Login already returns the account, so the profile screen has no reason
  /// to depend on a second round trip to show a name and an email. It sits
  /// in the encrypted store rather than plain preferences because it is
  /// personal data, and [clear] wipes it with the token.
  Future<String?> readProfile();
  Future<void> writeProfile(String json);

  /// Wipes BOTH the token and the cached profile.
  Future<void> clear();
}

/// Keychain (iOS) / EncryptedSharedPreferences (Android) implementation.
/// The token is a credential, so it never goes into plain SharedPreferences
/// (Guidelines 2.4).
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const String _key = 'playvo_auth_token';
  static const String _profileKey = 'playvo_auth_profile';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<String?> readProfile() => _storage.read(key: _profileKey);

  @override
  Future<void> writeProfile(String json) =>
      _storage.write(key: _profileKey, value: json);

  /// Both keys go, so signing out leaves no name or email on the device.
  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _profileKey);
  }
}

/// In-memory implementation for tests.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;
  String? _profile;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<String?> readProfile() async => _profile;

  @override
  Future<void> writeProfile(String json) async => _profile = json;

  @override
  Future<void> clear() async {
    _token = null;
    _profile = null;
  }
}