import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

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
  bool _isBiometricLoading = false;

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _buttonScaleAnim;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      resizeToAvoidBottomInset: true,
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
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                          horizontal: size.width > 400 ? 24 : 16,
                          vertical: isSmallScreen ? 16 : 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildLogo(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            _buildGlassCard(authVM, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildRegisterLink(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                      ? 20
                                      : 0,
                            ),
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

  Widget _buildLogo(bool isSmallScreen) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (_, __) => Container(
            width: isSmallScreen ? 70 : 88,
            height: isSmallScreen ? 70 : 88,
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
                  blurRadius: 28 +
                      (math.sin(_bgAnimController.value * 2 * math.pi) * 10),
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(Icons.shield_rounded,
                color: Colors.white, size: isSmallScreen ? 35 : 44),
          ),
        ),
        SizedBox(height: isSmallScreen ? 14 : 18),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
          ).createShader(bounds),
          child: Text(
            'CipherTask',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 28 : 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SECURE TASK MANAGEMENT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: isSmallScreen ? 9 : 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(AuthViewModel authVM, bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = math.sin(_shakeAnim.value * math.pi * 5) * 8;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
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
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20)),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome Back',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 20 : 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sign in to your secure vault',
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13)),
            SizedBox(height: isSmallScreen ? 20 : 28),
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AppConstants.validateEmail,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _onLoginPressed(),
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey(_obscurePassword),
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: AppConstants.validatePassword,
              isSmallScreen: isSmallScreen,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordInfo(context),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF00F5D4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: authVM.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => authVM.clearError(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF4D6D)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFFF4D6D), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(authVM.errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFFF4D6D),
                                        fontSize: 13)),
                              ),
                              const Icon(Icons.close_rounded,
                                  color: Color(0xFFFF4D6D), size: 16),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            _buildSignInButton(authVM),
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
        ),
      ),
    );
  }

  Widget _buildSignInButton(AuthViewModel authVM) {
    final isDisabled = authVM.isLoading;
    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          _buttonPressController.forward();
        }
      },
      onTapUp: (_) {
        _buttonPressController.reverse();
        if (!isDisabled) {
          _onLoginPressed();
        }
      },
      onTapCancel: () => _buttonPressController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonScaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _buttonScaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDisabled
                ? const LinearGradient(
                    colors: [Color(0xFF374151), Color(0xFF374151)])
                : const LinearGradient(
                    colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
          ),
          child: Center(
            child: authVM.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sign In',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AuthViewModel authVM) {
    final isDisabled = authVM.isLoading || _isBiometricLoading;
    return GestureDetector(
      onTap: isDisabled ? null : _onBiometricPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: isDisabled ? 0.02 : 0.05),
          border: Border.all(
              color: const Color(0xFF00F5D4)
                  .withValues(alpha: isDisabled ? 0.15 : 0.4),
              width: 1.2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isBiometricLoading
              ? const Row(
                  key: ValueKey('bio-loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.0, color: Color(0xFF00F5D4)),
                    ),
                    SizedBox(width: 12),
                    Text('Authenticating...',
                        style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                )
              : Row(
                  key: const ValueKey('bio-idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(width: 28),
                    Icon(Icons.fingerprint_rounded,
                        color: Color(0xFF00F5D4), size: 22),
                    SizedBox(width: 12),
                    Text('Unlock with Biometrics',
                        style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
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
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    List<String>? autofillHints,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
    bool isSmallScreen = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 16),
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  void _showForgotPasswordInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF00F5D4)),
            SizedBox(width: 12),
            Text(
              'Password Reset',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Password reset functionality would require backend integration. '
          'Please contact the administrator or create a new account.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF00F5D4)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginWithPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
    } else {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _onBiometricPressed() async {
    if (!mounted) return;
    setState(() => _isBiometricLoading = true);
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginWithBiometrics();
    if (!mounted) return;
    setState(() => _isBiometricLoading = false);
    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Biometric auth failed. Try password instead.'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

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
