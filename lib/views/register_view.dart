import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

/// RegisterView — Premium Redesign (M4 + M5)
/// Features: Animated orb background, glassmorphism card, gradient button
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: Stack(
        children: [
          // ── Animated Orb Background ─────────────────────────
          _AnimatedBackground(controller: _bgAnimController, size: size),

          // ── Back Button ─────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // ── Main Content ────────────────────────────────────
          SafeArea(
            child: Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildGlassCard(authVM),
                            const SizedBox(height: 24),
                            _buildLoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield_rounded, color: Color(0xFF00F5D4), size: 14),
              SizedBox(width: 6),
              Text(
                'CipherTask',
                style: TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFB0B8D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Create Your\nSecure Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your tasks. Encrypted. Always.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }

  // ── Glass Card ──────────────────────────────────────────────────
  Widget _buildGlassCard(AuthViewModel authVM) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Security indicator strip ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_rounded, color: Color(0xFF7B61FF), size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'End-to-end encrypted • AES-256 protected',
                    style: TextStyle(
                      color: Color(0xFF7B61FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Email ──────────────────────────────────────
          _buildInputField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: AppConstants.validateEmail,
          ),
          const SizedBox(height: 16),

          // ── Password ───────────────────────────────────
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: AppConstants.validatePassword,
          ),
          const SizedBox(height: 16),

          // ── Confirm Password ───────────────────────────
          _buildInputField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_person_outlined,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (val) => val != _passwordController.text
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 28),

          // ── Error Message ──────────────────────────────
          if (authVM.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF4D6D), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(authVM.errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFFF4D6D), fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Register Button ────────────────────────────
          _buildGradientButton(
            onPressed: authVM.isLoading ? null : _onRegisterPressed,
            isLoading: authVM.isLoading,
          ),

          const SizedBox(height: 16),

          // ── Terms note ─────────────────────────────────
          Center(
            child: Text(
              'Your data is stored locally & encrypted',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient Button ─────────────────────────────────────────────
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed == null
              ? const LinearGradient(
                  colors: [Color(0xFF374151), Color(0xFF374151)])
              : const LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF00F5D4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Login Link ──────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF00F5D4),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Reusable Input Field ────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: validator,
    );
  }

  // ── Action Handler ──────────────────────────────────────────────
  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    authVM.clearError();
    final success = await authVM.register(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
    }
  }
}

// ── Animated Background Orbs ──────────────────────────────────────
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
    // Purple orb — top right
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.85 + math.cos(a1) * 40,
        size.height * 0.15 + math.sin(a1) * 30);
    canvas.drawCircle(
        c1,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.25),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 200)));

    // Teal orb — bottom left
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.15 + math.cos(a2) * 50,
        size.height * 0.8 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.2),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 220)));

    // Indigo orb — center
    final a3 = t * 2 * math.pi * 0.6;
    final c3 = Offset(size.width * 0.5 + math.cos(a3) * 30,
        size.height * 0.5 + math.sin(a3) * 30);
    canvas.drawCircle(
        c3,
        160,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF4F6EF7).withValues(alpha: 0.12),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c3, radius: 160)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
