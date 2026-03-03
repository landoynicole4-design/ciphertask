import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

/// TodoListView — Premium Redesign (M5)
/// Features: Animated background, glassmorphism cards, gradient FAB,
///           Session auto-logout modal, Logout confirm modal with loading state
class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late SessionService _sessionService;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // ── START SESSION TIMER ─────────────────────────────────────────
    _sessionService = SessionService();
    _sessionService.start(onTimeout: _onSessionTimeout);
    // ───────────────────────────────────────────────────────────────

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoViewModel>().loadTodos();
    });
  }

  @override
  void dispose() {
    _sessionService.stop(); // prevent timer firing after widget is dead
    _bgAnimController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Session Timeout Modal ───────────────────────────────────────
  void _onSessionTimeout() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // force user to tap OK
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFFFF4D6D),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Session Expired',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You were inactive for 2 minutes.\nYour session has been locked for security.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              // Security badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Color(0xFFFF4D6D), size: 12),
                    SizedBox(width: 6),
                    Text(
                      'Auto-locked by CipherTask Security',
                      style: TextStyle(
                        color: Color(0xFFFF4D6D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Back to Login button
              GestureDetector(
                onTap: () async {
                  final authVM = context.read<AuthViewModel>();
                  final nav = Navigator.of(context);
                  Navigator.pop(ctx);
                  await authVM.logout();
                  if (mounted) {
                    nav.pushReplacementNamed(AppConstants.loginRoute);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D6D), Color(0xFFFF8C6B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D6D).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout with Confirm Modal + Loading ─────────────────────────
  void _onLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1020),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF7B61FF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Log Out?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your session will be securely terminated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loading state OR action buttons
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Color(0xFF7B61FF),
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Securing session...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm logout
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setModalState(() => isLoading = true);
                              _sessionService.stop();
                              final authVM = context.read<AuthViewModel>();
                              final nav = Navigator.of(context);
                              await authVM.logout();
                              if (mounted) {
                                nav.pop();
                                nav.pushReplacementNamed(
                                    AppConstants.loginRoute);
                              }
                            },
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7B61FF),
                                    Color(0xFF4F6EF7)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B61FF)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Yes, Logout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _sessionService.resetTimer(),
        child: Stack(
          children: [
            // ── Animated Background ───────────────────────────────
            _AnimatedBackground(controller: _bgAnimController, size: size),

            // ── Main Content ──────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildAppBar(context),
                    _buildStatsBar(),
                    Expanded(
                      child: Consumer<TodoViewModel>(
                        builder: (context, todoVM, _) {
                          if (todoVM.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00F5D4),
                                strokeWidth: 2.5,
                              ),
                            );
                          }
                          if (todoVM.todos.isEmpty) {
                            return _buildEmptyState();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: todoVM.todos.length,
                            itemBuilder: (context, index) {
                              final todo = todoVM.todos[index];
                              return _TodoCard(
                                todo: todo,
                                index: index,
                                onEdit: () =>
                                    _showAddEditDialog(existingTodo: todo),
                                onDelete: () => _confirmDelete(todo.id),
                                onToggle: () => todoVM.toggleComplete(todo.id),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating Action Button ────────────────────────────
            Positioned(
              bottom: 28,
              right: 24,
              child: _buildFAB(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom AppBar ───────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
            ).createShader(bounds),
            child: const Text(
              'CipherTask',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Spacer(),
          // Logout button — now triggers confirm modal
          GestureDetector(
            onTap: _onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: Color(0xFF6B7280), size: 16),
                  SizedBox(width: 6),
                  Text('Logout',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Bar ───────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Consumer<TodoViewModel>(
      builder: (context, todoVM, _) {
        final total = todoVM.todos.length;
        final done = todoVM.todos.where((t) => t.isCompleted).length;
        final pending = total - done;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _statItem(total.toString(), 'Total', const Color(0xFF00F5D4)),
              _statDivider(),
              _statItem(pending.toString(), 'Pending', const Color(0xFFFFB547)),
              _statDivider(),
              _statItem(done.toString(), 'Done', const Color(0xFF4ADE80)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded,
                        color: Color(0xFF00F5D4), size: 12),
                    SizedBox(width: 4),
                    Text('AES-256',
                        style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00F5D4).withValues(alpha: 0.15),
                  const Color(0xFF7B61FF).withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.shield_outlined,
                size: 48, color: Color(0xFF00F5D4)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Tasks Yet',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first encrypted task',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _showAddEditDialog(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('New Task',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit Bottom Sheet ─────────────────────────────────────
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      color: const Color(0xFF00F5D4),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Task' : 'New Secure Task',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _dialogField(titleCtrl, 'Task Title', Icons.title_rounded),
              const SizedBox(height: 12),
              _dialogField(
                  descCtrl, 'Description (optional)', Icons.notes_rounded),
              const SizedBox(height: 12),
              _dialogField(
                noteCtrl,
                '🔐 Secret Note — AES-256 Encrypted',
                Icons.lock_outline_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.2), size: 13),
                  const SizedBox(width: 6),
                  Text(
                    'Secret notes are encrypted before saving to DB',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              GestureDetector(
                onTap: () async {
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
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isEditing ? 'Update Task' : 'Save Task',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 16),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── Delete Confirmation ─────────────────────────────────────────
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Color(0xFFFF4D6D), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Task',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This action cannot be undone.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<TodoViewModel>().deleteTodo(id);
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF4D6D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFF4D6D)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Text('Delete',
                              style: TextStyle(
                                  color: Color(0xFFFF4D6D),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium Todo Card ─────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TodoCard({
    required this.todo,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF00F5D4),
      const Color(0xFF7B61FF),
      const Color(0xFFFFB547),
      const Color(0xFF4F6EF7),
    ];
    final accentColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: todo.isCompleted
              ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
              : accentColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox ─────────────────────────────────────
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.isCompleted
                      ? const Color(0xFF4ADE80)
                      : Colors.transparent,
                  border: Border.all(
                    color: todo.isCompleted
                        ? const Color(0xFF4ADE80)
                        : accentColor,
                    width: 2,
                  ),
                  boxShadow: todo.isCompleted
                      ? [
                          BoxShadow(
                              color: const Color(0xFF4ADE80)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // ── Content ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      color: todo.isCompleted
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration:
                          todo.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      todo.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Encrypted badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: accentColor, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'Encrypted note',
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ───────────────────────────────────────
            Column(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF6B7280), size: 16),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF4D6D), size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Background ───────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _AnimatedBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(size: size, painter: _OrbPainter(controller.value)),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.1 + math.cos(a1) * 30,
        size.height * 0.15 + math.sin(a1) * 20);
    canvas.drawCircle(
        c1,
        180,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.18),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 180)));

    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.9 + math.cos(a2) * 40,
        size.height * 0.6 + math.sin(a2) * 30);
    canvas.drawCircle(
        c2,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.14),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 200)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
