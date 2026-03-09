import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import 'key_storage_service.dart';

/// DatabaseService — Encrypted Local Database (M1)
///
/// Uses Hive with an encrypted box. The entire .hive file on disk is
/// encrypted — even if an attacker extracts the app's data folder via ADB,
/// they will only see random bytes.
///
/// FIX: All read operations now filter by [userId] so each account only
/// sees its own tasks. Tasks are stored in one shared encrypted box but
/// tagged with the owning user's email at write time.
class DatabaseService {
  final KeyStorageService _keyStorage;
  Box<TodoModel>? _todoBox;

  DatabaseService({required KeyStorageService keyStorage})
      : _keyStorage = keyStorage;

  /// Opens the encrypted Hive box.
  /// Must be called once before any CRUD operations.
  Future<void> openDatabase() async {
    String? storedKey = await _keyStorage.retrieveKey(
      AppConstants.hiveEncryptionKeyName,
    );

    Uint8List encryptionKey;

    if (storedKey == null) {
      encryptionKey = Uint8List.fromList(Hive.generateSecureKey());
      await _keyStorage.storeKey(
        AppConstants.hiveEncryptionKeyName,
        base64Encode(encryptionKey),
      );
    } else {
      encryptionKey = Uint8List.fromList(base64Decode(storedKey));
    }

    _todoBox = await Hive.openBox<TodoModel>(
      AppConstants.todoBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  // ─── CRUD Operations ──────────────────────────────────────────

  /// CREATE: Adds a new To-Do item to the encrypted database.
  /// The [todo] must already have [userId] set before calling this.
  Future<void> createTodo(TodoModel todo) async {
    _ensureOpen();
    await _todoBox!.put(todo.id, todo);
  }

  /// READ ALL: Returns only the tasks belonging to [userId].
  ///
  /// FIX: Previously returned all todos from the box regardless of owner.
  /// Now filters so Account A never sees Account B's tasks.
  List<TodoModel> getAllTodos({required String userId}) {
    _ensureOpen();
    return _todoBox!.values.where((todo) => todo.userId == userId).toList();
  }

  /// READ ONE: Returns a single To-Do by its ID, only if it belongs to [userId].
  TodoModel? getTodoById(String id, {required String userId}) {
    _ensureOpen();
    final todo = _todoBox!.get(id);
    // Guard: never return a task that belongs to a different user
    if (todo == null || todo.userId != userId) return null;
    return todo;
  }

  /// UPDATE: Replaces an existing To-Do item.
  Future<void> updateTodo(TodoModel todo) async {
    _ensureOpen();
    await _todoBox!.put(todo.id, todo);
  }

  /// DELETE: Permanently removes a To-Do item by ID.
  Future<void> deleteTodo(String id) async {
    _ensureOpen();
    await _todoBox!.delete(id);
  }

  /// Closes the Hive box. Call on logout or app close.
  Future<void> closeDatabase() async {
    await _todoBox?.close();
  }

  void _ensureOpen() {
    if (_todoBox == null || !_todoBox!.isOpen) {
      throw StateError('Database not open. Call openDatabase() first.');
    }
  }
}
