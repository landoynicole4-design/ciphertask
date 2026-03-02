import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

/// LoginView — Premium Redesign (M5)
/// Features: Animated orb background, glassmorphism card, gradient buttons
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _canUseBiometrics = false;

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
      duration: const Duration(seconds: 12),
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
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authVM = context.read<AuthViewModel>();
    final canUse = await authVM.canUseBiometrics();
    if (mounted) setState(() => _canUseBiometrics = canUse);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          _AnimatedBackground(controller: _bgAnimController, size: size),
          SafeArea(
            child: Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _buildLogo(),
                            const SizedBox(height: 32),
                            _buildGlassCard(authVM),
                            const SizedBox(height: 24),
                            _buildRegisterLink(),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child:
              const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
          ).createShader(bounds),
          child: const Text(
            'CipherTask',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'SECURE TASK MANAGEMENT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }

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
              offset: const Offset(0, 20)),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome Back',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Sign in to your secure vault',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 28),
          _buildInputField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: AppConstants.validateEmail,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 28),
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
          _buildGradientButton(
            onPressed: authVM.isLoading ? null : _onLoginPressed,
            isLoading: authVM.isLoading,
            label: 'Sign In',
            icon: Icons.arrow_forward_rounded,
          ),
          if (_canUseBiometrics) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 20),
            _buildBiometricButton(authVM),
          ],
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
    required IconData icon,
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
                  colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AuthViewModel authVM) {
    return GestureDetector(
      onTap: authVM.isLoading ? null : _onBiometricPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.4),
              width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: Color(0xFF00F5D4), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Unlock with Biometrics',
                style: TextStyle(
                    color: Color(0xFF00F5D4),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New to CipherTask? ",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.registerRoute),
          child: const Text('Create Account',
              style: TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

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
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: validator,
    );
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginWithPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
    }
  }

  Future<void> _onBiometricPressed() async {
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginWithBiometrics();
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
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.2 + math.cos(a1) * 40,
        size.height * 0.2 + math.sin(a1) * 30);
    canvas.drawCircle(
        c1,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.25),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 200)));

    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.85 + math.cos(a2) * 50,
        size.height * 0.75 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.22),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 220)));

    final a3 = t * 2 * math.pi * 0.7 + math.pi * 0.5;
    final c3 = Offset(size.width * 0.6 + math.cos(a3) * 35,
        size.height * 0.4 + math.sin(a3) * 35);
    canvas.drawCircle(
        c3,
        180,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF4F6EF7).withValues(alpha: 0.15),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c3, radius: 180)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
