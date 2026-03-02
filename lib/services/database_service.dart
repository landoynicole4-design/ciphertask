import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import 'key_storage_service.dart';

/// DatabaseService — Encrypted Local Database (M1)
///
/// Uses Hive with an encrypted box. This means the entire .hive file
/// on disk is encrypted — even if an attacker extracts the app's data
/// folder via ADB, they will only see random bytes (garbage data).
///
/// KEY FLOW:
///   1. On first run → generate a 32-byte random key → store in Keystore/Keychain
///   2. On subsequent runs → retrieve the same key → open the encrypted box
///
/// This is the ONLY class that talks directly to the database.
/// ViewModels should NEVER import Hive directly — they go through this service.
class DatabaseService {
  final KeyStorageService _keyStorage;
  Box<TodoModel>? _todoBox;

  DatabaseService({required KeyStorageService keyStorage})
      : _keyStorage = keyStorage;

  /// Opens the encrypted Hive box.
  ///
  /// Must be called once before any CRUD operations.
  /// Called in main.dart during app initialization.
  Future<void> openDatabase() async {
    // Step 1: Check if an encryption key already exists in secure storage
    String? storedKey = await _keyStorage.retrieveKey(
      AppConstants.hiveEncryptionKeyName,
    );

    Uint8List encryptionKey;

    if (storedKey == null) {
      // FIRST RUN: Generate a cryptographically secure 32-byte key.
      // Hive requires exactly 32 bytes for AES-256 box encryption.
      encryptionKey = Uint8List.fromList(Hive.generateSecureKey());

      // Store the key in hardware-backed secure storage (Keystore/Keychain).
      // We encode it as Base64 because FlutterSecureStorage stores strings.
      await _keyStorage.storeKey(
        AppConstants.hiveEncryptionKeyName,
        base64Encode(encryptionKey),
      );
    } else {
      // SUBSEQUENT RUNS: Decode the stored Base64 key back to bytes.
      // Fixed: explicitly cast to Uint8List via Uint8List.fromList()
      // because base64Decode returns List<int>, not Uint8List.
      encryptionKey = Uint8List.fromList(base64Decode(storedKey));
    }

    // Step 2: Open the encrypted Hive box using the key.
    // HiveAesCipher uses AES-256-CBC internally.
    _todoBox = await Hive.openBox<TodoModel>(
      AppConstants.todoBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  // ─── CRUD Operations ──────────────────────────────────────────

  /// CREATE: Adds a new To-Do item to the encrypted database.
  ///
  /// The [todo.secretNote] should already be AES-256 encrypted by
  /// EncryptionService BEFORE calling this method.
  Future<void> createTodo(TodoModel todo) async {
    _ensureOpen();
    await _todoBox!.put(todo.id, todo);
  }

  /// READ ALL: Returns all To-Do items for the current user.
  ///
  /// Note: secretNote values are returned as ciphertext.
  /// The ViewModel calls EncryptionService.decrypt() before displaying them.
  List<TodoModel> getAllTodos() {
    _ensureOpen();
    return _todoBox!.values.toList();
  }

  /// READ ONE: Returns a single To-Do by its ID.
  TodoModel? getTodoById(String id) {
    _ensureOpen();
    return _todoBox!.get(id);
  }

  /// UPDATE: Replaces an existing To-Do item.
  ///
  /// Uses the same key (todo.id) so Hive overwrites the old record.
  Future<void> updateTodo(TodoModel todo) async {
    _ensureOpen();
    await _todoBox!.put(todo.id, todo);
  }

  /// DELETE: Permanently removes a To-Do item by ID.
  Future<void> deleteTodo(String id) async {
    _ensureOpen();
    await _todoBox!.delete(id);
  }

  /// Closes the Hive box. Call this when the app is closing or on logout.
  Future<void> closeDatabase() async {
    await _todoBox?.close();
  }

  /// Guard: Throws if the database was not opened before use.
  void _ensureOpen() {
    if (_todoBox == null || !_todoBox!.isOpen) {
      throw StateError('Database not open. Call openDatabase() first.');
    }
  }
}
