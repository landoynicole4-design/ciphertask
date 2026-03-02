import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

/// TodoViewModel — Task CRUD with Encryption (M1 + M2)
///
/// This ViewModel sits between the UI and the data layer.
/// It handles all To-Do business logic and ensures that:
///   - secretNote is ALWAYS encrypted before going into the DB
///   - secretNote is ALWAYS decrypted before being shown in the UI
///
/// Views NEVER call DatabaseService or EncryptionService directly.
/// This strict separation is the core of MVVM.
class TodoViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  final Uuid _uuid = const Uuid();

  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────────────────
  List<TodoModel> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TodoViewModel({
    required DatabaseService databaseService,
    required EncryptionService encryptionService,
  })  : _databaseService = databaseService,
        _encryptionService = encryptionService;

  // ─── Load ──────────────────────────────────────────────────────

  /// Loads all To-Do items from the encrypted DB.
  ///
  /// Items are returned with ENCRYPTED secretNote values.
  /// The UI calls decryptNote() separately when it needs to display the note.
  Future<void> loadTodos() async {
    _setLoading(true);
    try {
      _todos = _databaseService.getAllTodos();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tasks: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Create ────────────────────────────────────────────────────

  /// Creates a new To-Do task.
  ///
  /// ENCRYPTION STEP: The [secretNote] is encrypted by EncryptionService
  /// BEFORE being passed to DatabaseService. The DB never sees plain text notes.
  ///
  /// Example:
  ///   Input:  secretNote = "Launch Codes: 9-Alpha-7"
  ///   Stored: secretNote = "U2FsdGVkX1+abc123..."  (ciphertext)
  Future<void> addTodo({
    required String title,
    required String description,
    required String secretNote,
  }) async {
    _setLoading(true);
    try {
      // ENCRYPT the sensitive note field before storing
      final encryptedNote = _encryptionService.encrypt(secretNote);

      final todo = TodoModel(
        id: _uuid.v4(), // Generate a unique UUID for this task
        title: title,
        description: description,
        secretNote: encryptedNote, // Only ciphertext goes into the DB
        createdAt: DateTime.now(),
      );

      await _databaseService.createTodo(todo);
      _todos.add(todo);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to create task: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update ────────────────────────────────────────────────────

  /// Updates an existing To-Do task.
  ///
  /// If [secretNote] is provided, it gets re-encrypted before saving.
  Future<void> updateTodo({
    required String id,
    String? title,
    String? description,
    String? secretNote,
    bool? isCompleted,
  }) async {
    _setLoading(true);
    try {
      final existing = _databaseService.getTodoById(id);
      if (existing == null) {
        _errorMessage = 'Task not found.';
        return;
      }

      // Encrypt the new secretNote only if it was changed
      String? encryptedNote;
      if (secretNote != null) {
        encryptedNote = _encryptionService.encrypt(secretNote);
      }

      final updated = existing.copyWith(
        title: title,
        description: description,
        secretNote: encryptedNote,
        isCompleted: isCompleted,
      );

      await _databaseService.updateTodo(updated);

      // Refresh local list
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) _todos[index] = updated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update task: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete ────────────────────────────────────────────────────

  /// Permanently deletes a To-Do task by ID.
  Future<void> deleteTodo(String id) async {
    try {
      await _databaseService.deleteTodo(id);
      _todos.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete task: ${e.toString()}';
      notifyListeners();
    }
  }

  // ─── Toggle Complete ───────────────────────────────────────────

  /// Toggles the isCompleted status of a task.
  Future<void> toggleComplete(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    await updateTodo(id: id, isCompleted: !todo.isCompleted);
  }

  // ─── Decrypt Note (for Display) ────────────────────────────────

  /// Decrypts a task's secretNote for display in the UI.
  ///
  /// This is called ONLY when the user explicitly opens a task's detail view.
  /// We don't decrypt all notes at once to minimize exposure of sensitive data.
  String decryptNote(String encryptedNote) {
    try {
      return _encryptionService.decrypt(encryptedNote);
    } catch (e) {
      return '[Decryption failed]';
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
