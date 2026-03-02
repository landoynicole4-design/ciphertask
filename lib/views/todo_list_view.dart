import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../utils/constants.dart';

/// TodoListView — Main Secure Task List Screen (M5)
///
/// Displays all encrypted To-Do tasks. Users can add, edit, toggle, delete.
/// Connected to TodoViewModel via Consumer (Provider pattern).
///
/// MVVM Rule: This view never calls DatabaseService or EncryptionService.
/// All actions go through TodoViewModel.
class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  @override
  void initState() {
    super.initState();
    // Load tasks when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoViewModel>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1226),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFF4ECDC4), size: 20),
            SizedBox(width: 8),
            Text('CipherTask',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: Consumer<TodoViewModel>(
        builder: (context, todoVM, _) {
          if (todoVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            );
          }

          if (todoVM.todos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todoVM.todos.length,
            itemBuilder: (context, index) {
              final todo = todoVM.todos[index];
              return _TodoCard(
                todo: todo,
                todoVM: todoVM,
                onEdit: () => _showAddEditDialog(existingTodo: todo),
                onDelete: () => _confirmDelete(todo.id),
                onToggle: () => todoVM.toggleComplete(todo.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Task',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fixed: added const to Column and all children
          Icon(Icons.shield_outlined, size: 80, color: Color(0xFF4ECDC4)),
          SizedBox(height: 16),
          Text('No Tasks Yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Tap + to add your first secure task',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ─── Add / Edit Dialog ─────────────────────────────────────────
  void _showAddEditDialog({TodoModel? existingTodo}) {
    final isEditing = existingTodo != null;
    final titleCtrl =
        TextEditingController(text: isEditing ? existingTodo.title : '');
    final descCtrl =
        TextEditingController(text: isEditing ? existingTodo.description : '');
    final noteCtrl = TextEditingController(
      text: isEditing
          ? context.read<TodoViewModel>().decryptNote(existingTodo.secretNote)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'New Secure Task',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _dialogField(titleCtrl, 'Task Title', Icons.title),
              const SizedBox(height: 12),
              _dialogField(descCtrl, 'Description', Icons.description_outlined),
              const SizedBox(height: 12),
              _dialogField(
                noteCtrl,
                '🔐 Secret Note (AES-256 Encrypted)',
                Icons.lock_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              const Text(
                'Secret notes are AES-256 encrypted before saving.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final todoVM = context.read<TodoViewModel>();
                  if (isEditing) {
                    await todoVM.updateTodo(
                      id: existingTodo.id,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      secretNote: noteCtrl.text,
                    );
                  } else {
                    await todoVM.addTodo(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      secretNote: noteCtrl.text,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? 'Update Task' : 'Save Task',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4ECDC4), size: 20),
        filled: true,
        fillColor: const Color(0xFF1A2035),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
        ),
      ),
    );
  }

  // ─── Delete Confirmation ────────────────────────────────────────
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1226),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure? This cannot be undone.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TodoViewModel>().deleteTodo(id);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────
  void _onLogout() async {
    await context.read<AuthViewModel>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    }
  }
}

// ─── Todo Card Widget ─────────────────────────────────────────────

/// A reusable card widget that displays one To-Do item.
class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final TodoViewModel todoVM;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TodoCard({
    required this.todo,
    required this.todoVM,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // Fixed: replaced deprecated withOpacity with withValues
          color: todo.isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFF4ECDC4).withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: todo.isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(
                color:
                    todo.isCompleted ? Colors.green : const Color(0xFF4ECDC4),
                width: 2,
              ),
            ),
            child: todo.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isCompleted ? Colors.grey : Colors.white,
            fontWeight: FontWeight.w600,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(todo.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            const SizedBox(height: 6),
            // Fixed: added const to Row and its constant children
            const Row(
              children: [
                Icon(Icons.lock, color: Color(0xFF4ECDC4), size: 12),
                SizedBox(width: 4),
                Text(
                  'Encrypted note stored',
                  style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
