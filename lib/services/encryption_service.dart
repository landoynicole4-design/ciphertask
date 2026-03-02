import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import '../utils/constants.dart';
import 'key_storage_service.dart';

/// EncryptionService — AES-256 Field-Level Encryption
///
/// Responsibility: Encrypt and decrypt the [secretNote] field of a To-Do item.
///
/// WHY field-level encryption?
/// Even though the Hive DB itself is encrypted, adding a second layer of
/// AES-256 encryption on sensitive fields means that even if the DB key
/// is somehow compromised, the secret notes are STILL protected.
///
/// Flow:
///   ENCRYPT: plaintext → AES-256-CBC → Base64 ciphertext → stored in DB
///   DECRYPT: ciphertext from DB → Base64 decode → AES-256-CBC → plaintext
class EncryptionService {
  final KeyStorageService _keyStorage;

  // Internal AES encrypter — initialized lazily on first use
  enc.Encrypter? _encrypter;
  enc.IV? _iv;

  EncryptionService({required KeyStorageService keyStorage})
      : _keyStorage = keyStorage;

  /// Initialize the AES encrypter.
  ///
  /// On FIRST RUN: Generates a random 256-bit (32-byte) AES key and a
  ///               128-bit (16-byte) IV. Stores both in FlutterSecureStorage.
  ///
  /// On SUBSEQUENT RUNS: Retrieves existing key and IV from secure storage.
  ///
  /// This ensures the same key is used every time, so data encrypted on
  /// a previous session can be decrypted on the next session.
  Future<void> initialize() async {
    String? storedKey =
        await _keyStorage.retrieveKey(AppConstants.aesSecretKeyName);
    String? storedIv = await _keyStorage.retrieveKey(AppConstants.aesIvKeyName);

    if (storedKey == null || storedIv == null) {
      // FIRST RUN: Generate cryptographically secure random key and IV
      final key = enc.Key.fromSecureRandom(32); // 256 bits = AES-256
      final iv = enc.IV.fromSecureRandom(16); // 128-bit IV for CBC mode

      // Persist to hardware-backed secure storage
      await _keyStorage.storeKey(
        AppConstants.aesSecretKeyName,
        base64Encode(key.bytes),
      );
      await _keyStorage.storeKey(
        AppConstants.aesIvKeyName,
        base64Encode(iv.bytes),
      );

      _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      _iv = iv;
    } else {
      // SUBSEQUENT RUNS: Restore key and IV from secure storage
      final keyBytes = base64Decode(storedKey);
      final ivBytes = base64Decode(storedIv);

      final key = enc.Key(Uint8List.fromList(keyBytes));
      _iv = enc.IV(Uint8List.fromList(ivBytes));
      _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    }
  }

  /// Encrypts a plain text string using AES-256-CBC.
  ///
  /// Returns a Base64-encoded ciphertext string.
  /// Example: "Launch Codes" → "U2FsdGVkX1+abc123..."
  String encrypt(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }
    final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
    return encrypted.base64; // Return as Base64 string for safe DB storage
  }

  /// Decrypts a Base64-encoded AES-256-CBC ciphertext string.
  ///
  /// Returns the original plain text.
  /// Example: "U2FsdGVkX1+abc123..." → "Launch Codes"
  String decrypt(String cipherText) {
    if (_encrypter == null || _iv == null) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }
    final encrypted = enc.Encrypted.fromBase64(cipherText);
    return _encrypter!.decrypt(encrypted, iv: _iv!);
  }
}
