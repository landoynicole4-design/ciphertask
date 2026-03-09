import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

/// TodoViewModel — Task CRUD with Encryption (M1 + M2)
///
/// [currentUserId] is nullable to support the initial state before login.
/// Once the user logs in, ProxyProvider in main.dart calls update() which
/// rebuilds this ViewModel with the real userId, triggering loadTodos().
class TodoViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  final Uuid _uuid = const Uuid();

  // Nullable: null = not logged in yet, String = logged-in user's email
  String? _currentUserId;

  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────────────────
  List<TodoModel> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  TodoViewModel({
    required DatabaseService databaseService,
    required EncryptionService encryptionService,
    String? currentUserId, // ← nullable: safe before login
  })  : _databaseService = databaseService,
        _encryptionService = encryptionService,
        _currentUserId = currentUserId {
    // Auto-load tasks if userId is already known at construction time
    if (_currentUserId != null) {
      loadTodos();
    }
  }

  /// Called by ProxyProvider on login/logout/account switch.
  /// Reloads tasks only if the user actually changed.
  void setCurrentUser(String? userId) {
    if (_currentUserId == userId) return; // no change, skip reload
    _currentUserId = userId;
    _todos = [];
    notifyListeners();
    if (userId != null) loadTodos();
  }

  // ─── Load ──────────────────────────────────────────────────────

  /// Loads only the tasks that belong to the current user.
  Future<void> loadTodos() async {
    if (_currentUserId == null) return; // guard: no user = no tasks
    _setLoading(true);
    try {
      _todos = _databaseService.getAllTodos(userId: _currentUserId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tasks: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Create ────────────────────────────────────────────────────

  /// Creates a new To-Do task tagged with the current user's ID.
  Future<void> addTodo({
    required String title,
    required String description,
    required String secretNote,
  }) async {
    if (_currentUserId == null) return; // guard
    _setLoading(true);
    try {
      final encryptedNote = _encryptionService.encrypt(secretNote);

      final todo = TodoModel(
        userId: _currentUserId!,
        id: _uuid.v4(),
        title: title,
        description: description,
        secretNote: encryptedNote,
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

  Future<void> updateTodo({
    required String id,
    String? title,
    String? description,
    String? secretNote,
    bool? isCompleted,
  }) async {
    if (_currentUserId == null) return; // guard
    _setLoading(true);
    try {
      final existing =
          _databaseService.getTodoById(id, userId: _currentUserId!);
      if (existing == null) {
        _errorMessage = 'Task not found.';
        return;
      }

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

  // ─── Delete All ────────────────────────────────────────────────

  Future<void> deleteAllTodos() async {
    _setLoading(true);
    try {
      final ids = List<String>.from(_todos.map((t) => t.id));
      for (final id in ids) {
        await _databaseService.deleteTodo(id);
      }
      _todos.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete all tasks: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Toggle Complete ───────────────────────────────────────────

  Future<void> toggleComplete(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    await updateTodo(id: id, isCompleted: !todo.isCompleted);
  }

  // ─── Decrypt Note ──────────────────────────────────────────────

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
