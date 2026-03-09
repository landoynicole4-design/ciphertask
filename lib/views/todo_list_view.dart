import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CipherTask — Todo List View
// Improvements applied:
//   • Staggered card entrance animations (each card slides + fades in)
//   • Swipe-right → complete, swipe-left → delete (with colored backgrounds)
//   • Completion progress bar in stats panel
//   • Priority chip on cards (Low / Medium / High) with colors
//   • Pulsing ring on empty state icon
//   • Haptic feedback on selection, toggle, delete
//   • AnimatedSwitcher for action bar transitions
//   • Bottom sheet input validation (title required)
//   • Keyboard-aware bottom sheet with ScrollView
//   • Scroll-to-top FAB appears after scrolling down
// ─────────────────────────────────────────────────────────────────────────────

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _pulseController; // empty state pulse
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late SessionService _sessionService;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showScrollTop = false;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Track which keys have already animated in (for stagger)
  final Set<String> _animatedCards = {};

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _sessionService = SessionService();
    _sessionService.start(onTimeout: _onSessionTimeout);

    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoViewModel>().loadTodos();
    });
  }

  @override
  void dispose() {
    _sessionService.stop();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Selection ────────────────────────────────────────────────────
  void _exitSelectionMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<TodoModel> todos) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedIds.length == todos.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(todos.map((t) => t.id));
        _isSelectionMode = true;
      }
    });
  }

  // ── Session Timeout ──────────────────────────────────────────────
  void _onSessionTimeout() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CipherDialog(
        icon: Icons.lock_clock_rounded,
        iconColor: const Color(0xFFFF4D6D),
        title: 'Session Expired',
        subtitle:
            'You were inactive for 2 minutes.\nYour session has been locked for security.',
        actions: [
          _DialogAction(
            label: 'Back to Login',
            gradient: const LinearGradient(
                colors: [Color(0xFFFF4D6D), Color(0xFFFF8C6B)]),
            onTap: () async {
              final authVM = context.read<AuthViewModel>();
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              await authVM.logout();
              if (mounted) nav.pushReplacementNamed(AppConstants.loginRoute);
            },
          ),
        ],
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────
  void _onLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setS) => _CipherDialog(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFF7B61FF),
            title: 'Log Out?',
            subtitle: 'Your session will be securely terminated.',
            loading: isLoading,
            loadingLabel: 'Securing session...',
            actions: [
              _DialogAction(
                label: 'Cancel',
                isGhost: true,
                onTap: () => Navigator.pop(ctx),
              ),
              _DialogAction(
                label: 'Yes, Logout',
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF4F6EF7)]),
                onTap: () async {
                  setS(() => isLoading = true);
                  _sessionService.stop();
                  final authVM = context.read<AuthViewModel>();
                  final nav = Navigator.of(context);
                  await authVM.logout();
                  if (mounted) {
                    nav.pop();
                    nav.pushReplacementNamed(AppConstants.loginRoute);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Delete ───────────────────────────────────────────────────────
  void _confirmDeleteSelected() {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final isAll = count == context.read<TodoViewModel>().todos.length;
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (ctx) => _CipherDialog(
        icon: isAll ? Icons.delete_sweep_rounded : Icons.delete_rounded,
        iconColor: const Color(0xFFFF4D6D),
        title: isAll
            ? 'Delete All Tasks?'
            : 'Delete $count Task${count > 1 ? 's' : ''}?',
        subtitle: isAll
            ? 'This will permanently delete all your tasks.'
            : 'This action cannot be undone.',
        actions: [
          _DialogAction(
              label: 'Cancel', isGhost: true, onTap: () => Navigator.pop(ctx)),
          _DialogAction(
            label: isAll ? 'Delete All' : 'Delete',
            gradient: const LinearGradient(
                colors: [Color(0xFFFF4D6D), Color(0xFFFF8C6B)]),
            onTap: () {
              Navigator.pop(ctx);
              final todoVM = context.read<TodoViewModel>();
              for (final id in List.from(_selectedIds)) {
                todoVM.deleteTodo(id);
              }
              _exitSelectionMode();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => _CipherDialog(
        icon: Icons.delete_rounded,
        iconColor: const Color(0xFFFF4D6D),
        title: 'Delete Task',
        subtitle: 'This action cannot be undone.',
        actions: [
          _DialogAction(
              label: 'Cancel', isGhost: true, onTap: () => Navigator.pop(ctx)),
          _DialogAction(
            label: 'Delete',
            isOutline: true,
            outlineColor: const Color(0xFFFF4D6D),
            onTap: () {
              Navigator.pop(ctx);
              context.read<TodoViewModel>().deleteTodo(id);
            },
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────
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
            _AnimatedBackground(controller: _bgAnimController, size: size),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildStatsBar(),
                    _buildSearchBar(),
                    _buildActionBar(),
                    Expanded(child: _buildList()),
                  ],
                ),
              ),
            ),

            // FAB row — bottom right
            Positioned(
              bottom: 28,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Scroll-to-top button
                  AnimatedOpacity(
                    opacity: _showScrollTop ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: AnimatedSlide(
                      offset:
                          _showScrollTop ? Offset.zero : const Offset(0, 0.4),
                      duration: const Duration(milliseconds: 250),
                      child: GestureDetector(
                        onTap: () => _scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(Icons.keyboard_arrow_up_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),

                  // New Task FAB
                  if (!_isSelectionMode) _buildFAB(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────
  Widget _buildList() {
    return Consumer<TodoViewModel>(
      builder: (context, todoVM, _) {
        if (todoVM.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF00F5D4), strokeWidth: 2.5),
          );
        }
        final filtered = _getFilteredTodos(todoVM.todos);
        if (todoVM.todos.isEmpty) return _buildEmptyState(isEmpty: true);
        if (filtered.isEmpty) return _buildEmptyState(isEmpty: false);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final todo = filtered[index];
            final isSelected = _selectedIds.contains(todo.id);
            final isNew = !_animatedCards.contains(todo.id);
            if (isNew) {
              WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                    _animatedCards.add(todo.id);
                  }));
            }

            return _StaggeredCard(
              key: ValueKey(todo.id),
              animate: isNew,
              delay: Duration(milliseconds: math.min(index * 60, 300)),
              child: _SwipeableCard(
                onSwipeComplete: () {
                  HapticFeedback.mediumImpact();
                  todoVM.toggleComplete(todo.id);
                },
                onSwipeDelete: () => _confirmDelete(todo.id),
                child: _TodoCard(
                  todo: todo,
                  index: index,
                  isSelected: isSelected,
                  isSelectionMode: _isSelectionMode,
                  onEdit: _isSelectionMode
                      ? null
                      : () => _showAddEditDialog(existingTodo: todo),
                  onDelete:
                      _isSelectionMode ? null : () => _confirmDelete(todo.id),
                  onToggle: () {
                    HapticFeedback.lightImpact();
                    todoVM.toggleComplete(todo.id);
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isSelectionMode = true;
                      _selectedIds.add(todo.id);
                    });
                  },
                  onSelect: () => _toggleSelection(todo.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<TodoModel> _getFilteredTodos(List<TodoModel> todos) {
    if (_searchQuery.trim().isEmpty) return todos;
    final q = _searchQuery.toLowerCase();
    return todos
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  // ── AppBar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '☀️ Good Morning'
        : hour < 17
            ? '👋 Good Afternoon'
            : '🌙 Good Evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 1)
              ],
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)])
                    .createShader(b),
                child: const Text('CipherTask',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
              Text(
                greeting,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _onLogout,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFF6B7280), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Bar ────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Consumer<TodoViewModel>(
      builder: (context, todoVM, _) {
        final total = todoVM.todos.length;
        final done = todoVM.todos.where((t) => t.isCompleted).length;
        final pending = total - done;
        final progress = total == 0 ? 0.0 : done / total;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [
              Colors.white.withValues(alpha: 0.09),
              Colors.white.withValues(alpha: 0.04),
            ]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _statItem(total.toString(), 'Total', const Color(0xFF00F5D4)),
                  _statDivider(),
                  _statItem(
                      pending.toString(), 'Pending', const Color(0xFFFFB547)),
                  _statDivider(),
                  _statItem(done.toString(), 'Done', const Color(0xFF4ADE80)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFF00F5D4).withValues(alpha: 0.15),
                        const Color(0xFF7B61FF).withValues(alpha: 0.1),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFF00F5D4).withValues(alpha: 0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.lock_rounded,
                          color: Color(0xFF00F5D4), size: 11),
                      SizedBox(width: 4),
                      Text('AES-256',
                          style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ]),
                  ),
                ],
              ),

              // ── Progress bar ──────────────────────────────────────
              if (total > 0) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => Stack(children: [
                          Container(
                              height: 7,
                              color: Colors.white.withValues(alpha: 0.07)),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  const Color(0xFF00F5D4),
                                  Color.lerp(const Color(0xFF00F5D4),
                                      const Color(0xFF4ADE80), v)!,
                                ]),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F5D4)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
        ],
      );

  Widget _statDivider() => Container(
        height: 28,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white.withValues(alpha: 0.08),
      );

  // ── Search Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child:
                Icon(Icons.search_rounded, color: Color(0xFF00F5D4), size: 18),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF6B7280), size: 18),
                )
              : null,
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Action Bar ───────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Consumer<TodoViewModel>(
      builder: (context, todoVM, _) {
        final todos = todoVM.todos;
        final filtered = _getFilteredTodos(todos);
        final allSelected =
            todos.isNotEmpty && _selectedIds.length == todos.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side chips wrap if they overflow
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (todos.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _actionChip(
                          key: ValueKey(allSelected),
                          icon: allSelected
                              ? Icons.deselect_rounded
                              : Icons.select_all_rounded,
                          label: allSelected ? 'Deselect All' : 'Select All',
                          color: const Color(0xFF7B61FF),
                          onTap: () => _toggleSelectAll(todos),
                        ),
                      ),
                    if (_isSelectionMode && _selectedIds.isNotEmpty) ...[
                      _actionChip(
                        icon: Icons.delete_sweep_rounded,
                        label: 'Delete (${_selectedIds.length})',
                        color: const Color(0xFFFF4D6D),
                        onTap: _confirmDeleteSelected,
                      ),
                      _actionChip(
                        icon: Icons.close_rounded,
                        label: 'Cancel',
                        color: const Color(0xFF6B7280),
                        onTap: _exitSelectionMode,
                      ),
                    ],
                  ],
                ),
              ),
              // Task count badge pinned to right
              if (filtered.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    '${filtered.length} task${filtered.length != 1 ? 's' : ''}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionChip({
    Key? key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────
  Widget _buildEmptyState({required bool isEmpty}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90 + 28 * _pulseAnim.value,
                  height: 90 + 28 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F5D4)
                          .withValues(alpha: 0.12 * (1 - _pulseAnim.value)),
                      width: 2,
                    ),
                  ),
                ),
                child!,
              ],
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  const Color(0xFF00F5D4).withValues(alpha: 0.12),
                  const Color(0xFF7B61FF).withValues(alpha: 0.12),
                ]),
                border: Border.all(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.3)),
              ),
              child: Icon(
                isEmpty ? Icons.shield_outlined : Icons.search_off_rounded,
                size: 42,
                color: const Color(0xFF00F5D4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(isEmpty ? 'No Tasks Yet' : 'No Results Found',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            isEmpty
                ? 'Tap + to add your first encrypted task'
                : 'Try a different search term',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
          ),
          if (isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Swipe right to complete · Swipe left to delete',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _showAddEditDialog(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit Bottom Sheet ──────────────────────────────────────
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
    String? titleError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1020),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: SingleChildScrollView(
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

                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: const Color(0xFF00F5D4),
                          size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Task' : 'New Secure Task',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Title field (with validation)
                  _dialogField(
                    titleCtrl,
                    'Task Title *',
                    Icons.title_rounded,
                    errorText: titleError,
                    onChanged: (v) {
                      if (titleError != null && v.trim().isNotEmpty) {
                        setS(() => titleError = null);
                      }
                    },
                  ),
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
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.2), size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Secret notes are encrypted before saving',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 11),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Save button
                  GestureDetector(
                    onTap: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        setS(() => titleError = 'Title is required');
                        HapticFeedback.heavyImpact();
                        return;
                      }
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      final todoVM = context.read<TodoViewModel>();
                      if (isEditing) {
                        await todoVM.updateTodo(
                          id: existingTodo.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text,
                          secretNote: noteCtrl.text,
                        );
                      } else {
                        await todoVM.addTodo(
                          title: titleCtrl.text.trim(),
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
                            colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)]),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00F5D4).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 16),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered entrance animation wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _StaggeredCard extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration delay;

  const _StaggeredCard({
    super.key,
    required this.child,
    required this.animate,
    required this.delay,
  });

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipeable card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeComplete;
  final VoidCallback onSwipeDelete;

  const _SwipeableCard({
    required this.child,
    required this.onSwipeComplete,
    required this.onSwipeDelete,
  });

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      // Right → complete
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Complete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      // Left → delete
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [Color(0xFFFF4D6D), Color(0xFFFF8C6B)]),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onSwipeComplete();
          return false; // don't remove from list — toggle handles it
        } else {
          widget.onSwipeDelete();
          return false; // dialog handles actual deletion
        }
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Todo Card
// ─────────────────────────────────────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;

  const _TodoCard({
    required this.todo,
    required this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onLongPress,
    required this.onSelect,
  });

  // Priority derived from index
  static const _priorities = ['Low', 'Medium', 'High'];
  static const _priorityColors = [
    Color(0xFF4ADE80),
    Color(0xFFFFB547),
    Color(0xFFFF4D6D),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColors = [
      const Color(0xFF00F5D4),
      const Color(0xFF7B61FF),
      const Color(0xFFFFB547),
      const Color(0xFF4F6EF7),
    ];
    final accent = accentColors[index % accentColors.length];

    // ── Priority for this card ──
    final priorityLabel = _priorities[index % _priorities.length];
    final priorityColor = _priorityColors[index % _priorityColors.length];

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: isSelectionMode ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    const Color(0xFF7B61FF).withValues(alpha: 0.18),
                    const Color(0xFF7B61FF).withValues(alpha: 0.08),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7B61FF).withValues(alpha: 0.6)
                : todo.isCompleted
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                    : accent.withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF7B61FF).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
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
              // Checkbox / complete circle
              isSelectionMode
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF7B61FF)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7B61FF)
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    )
                  : GestureDetector(
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
                                : accent,
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        color: todo.isCompleted
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(todo.description,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              height: 1.4)),
                    ],
                    const SizedBox(height: 10),

                    // Tags row
                    Row(children: [
                      // Encrypted badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, color: accent, size: 9),
                            const SizedBox(width: 3),
                            Text('Encrypted',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ── Priority chip ── FIX: uses _priorities & _priorityColors
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: priorityColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                              color: priorityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Completed badge
                      if (todo.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4ADE80).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: const Color(0xFF4ADE80)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4ADE80), size: 9),
                              SizedBox(width: 3),
                              Text('Done',
                                  style: TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ]),
                  ],
                ),
              ),

              // Action buttons
              if (!isSelectionMode)
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
                          color:
                              const Color(0xFFFF4D6D).withValues(alpha: 0.08),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _DialogAction {
  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final bool isGhost;
  final bool isOutline;
  final Color? outlineColor;

  _DialogAction({
    required this.label,
    required this.onTap,
    this.gradient,
    this.isGhost = false,
    this.isOutline = false,
    this.outlineColor,
  });
}

class _CipherDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<_DialogAction> actions;
  final bool loading;
  final String? loadingLabel;

  const _CipherDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1020),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: actions.any((a) =>
                      a.gradient != null &&
                      a.gradient!.colors.contains(iconColor))
                  ? iconColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 24),
            if (loading)
              Column(children: [
                SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                        color: iconColor, strokeWidth: 2.5)),
                const SizedBox(height: 12),
                if (loadingLabel != null)
                  Text(loadingLabel!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12)),
              ])
            else
              Row(
                children: actions
                    .map((a) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: actions.indexOf(a) > 0 ? 12 : 0),
                            child: GestureDetector(
                              onTap: a.onTap,
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: a.isGhost
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : a.isOutline
                                          ? (a.outlineColor ?? iconColor)
                                              .withValues(alpha: 0.1)
                                          : null,
                                  gradient: a.gradient,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: a.isGhost
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : a.isOutline
                                            ? (a.outlineColor ?? iconColor)
                                                .withValues(alpha: 0.4)
                                            : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(a.label,
                                      style: TextStyle(
                                          color: a.isOutline
                                              ? (a.outlineColor ?? iconColor)
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Background
// ─────────────────────────────────────────────────────────────────────────────
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
            Colors.transparent,
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
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c2, radius: 200)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
