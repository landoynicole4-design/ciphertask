import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// KeyStorageService — Hardware-Backed Key Storage Wrapper
///
/// This service wraps FlutterSecureStorage, which uses:
///   - Android Keystore on Android devices
///   - iOS Keychain on Apple devices
///
/// NEVER store encryption keys in SharedPreferences or plain files.
/// Those are readable by other apps or via ADB backup.
/// Hardware enclaves make key extraction nearly impossible.
class KeyStorageService {
  // FlutterSecureStorage options:
  // - Android: uses EncryptedSharedPreferences backed by Android Keystore
  // - iOS: uses Keychain with accessibility kSecAttrAccessibleWhenUnlocked
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Uses Android Keystore
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // iOS Keychain
    ),
  );

  /// Stores a key-value pair securely in the hardware enclave.
  ///
  /// [key]   - The identifier (e.g., 'hive_encryption_key')
  /// [value] - The secret value to store
  Future<void> storeKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieves a stored value by its key.
  ///
  /// Returns null if the key does not exist (first app run).
  Future<String?> retrieveKey(String key) async {
    return await _storage.read(key: key);
  }

  /// Checks whether a key exists in secure storage.
  Future<bool> hasKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  /// Deletes a specific key from secure storage.
  /// Use this on logout or when rotating encryption keys.
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  /// Deletes ALL stored keys. Use only on full app reset.
  Future<void> deleteAllKeys() async {
    await _storage.deleteAll();
  }
}
