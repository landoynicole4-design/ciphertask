import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';
import 'widgets/cipher_logo.dart';
import 'widgets/login_success_modal.dart';

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

  // Fix: auto-dismiss timer for the error banner
  Timer? _errorDismissTimer;

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

  /// Fix: starts a 4s auto-dismiss timer whenever a new error appears.
  /// Cancels any previous timer first so repeated errors restart cleanly.
  void _scheduleErrorDismiss(AuthViewModel authVM) {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) authVM.clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorDismissTimer?.cancel();
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
      // Fix: true so keyboard never covers input fields on short devices
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgAnimController, size: size),
          SafeArea(
            child: Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                // Trigger auto-dismiss whenever a new error is present
                if (authVM.errorMessage != null) {
                  _scheduleErrorDismiss(authVM);
                }

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    // Fix: SingleChildScrollView prevents keyboard occlusion
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width > 400 ? 24 : 16,
                        vertical: isSmallScreen ? 12 : 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Fix: tighter gap between logo and card for cohesion
                            _buildLogo(size),
                            SizedBox(height: isSmallScreen ? 14 : 18),
                            _buildGlassCard(authVM),
                            const SizedBox(height: 16),
                            _buildRegisterLink(),
                            const SizedBox(height: 20),
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

  Widget _buildLogo(Size size) {
    final logoSize = size.height < 700 ? 52.0 : 64.0;
    return CipherTaskLogo(
      size: logoSize,
      animated: true,
      showText: true,
      showTagline: true,
    );
  }

  Widget _buildGlassCard(AuthViewModel authVM) {
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // mainAxisSize.min so the card doesn't expand to fill Expanded
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to your secure vault',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),

            const SizedBox(height: 24),

            // ── Email ───────────────────────────────────────────────
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AppConstants.validateEmail,
            ),
            const SizedBox(height: 14),

            // ── Password ────────────────────────────────────────────
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _onLoginPressed(),
              // Fix: shows minimum length hint before submission attempt
              helperText: 'Minimum 8 characters',
              suffixIcon: IconButton(
                // Fix: tooltip used as semanticsLabel for screen readers
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showForgotPasswordInfo(context),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                      color: Color(0xFF00F5D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Error banner ────────────────────────────────────────
            // Fix: tap to dismiss OR auto-dismisses after 4 seconds
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: authVM.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () {
                          _errorDismissTimer?.cancel();
                          authVM.clearError();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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
                                  color: Color(0xFFFF4D6D), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authVM.errorMessage!,
                                  style: const TextStyle(
                                      color: Color(0xFFFF4D6D), fontSize: 12),
                                ),
                              ),
                              const Icon(Icons.close_rounded,
                                  color: Color(0xFFFF4D6D), size: 14),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Sign In button (spinner is inside — no screen freeze) ──
            _buildSignInButton(authVM),

            const SizedBox(height: 24),

            // Biometric always visible; access guarded at runtime
            Row(
              children: [
                Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 16),
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
        if (!isDisabled) _buttonPressController.forward();
      },
      onTapUp: (_) {
        _buttonPressController.reverse();
        if (!isDisabled) _onLoginPressed();
      },
      onTapCancel: () => _buttonPressController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonScaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _buttonScaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
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
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sign In',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 17),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AuthViewModel authVM) {
    final isDisabled = authVM.isLoading || _isBiometricLoading;
    return Semantics(
      // Fix: screen readers announce this as "Unlock with biometrics, button"
      label: 'Unlock with biometrics',
      button: true,
      child: GestureDetector(
        onTap: isDisabled ? null : _onBiometricPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
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
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.0, color: Color(0xFF00F5D4)),
                      ),
                      SizedBox(width: 10),
                      Text('Authenticating...',
                          style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Row(
                    key: ValueKey('bio-idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint_rounded,
                          color: Color(0xFF00F5D4), size: 24),
                      SizedBox(width: 10),
                      Text('Unlock with Biometrics',
                          style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('New to CipherTask? ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.registerRoute),
          child: const Text('Create Account',
              style: TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 13,
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
    // Fix: optional helper text for pre-validation hints (e.g. min length)
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        helperText: helperText,
        helperStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.28), fontSize: 11),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 11),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF00F5D4)),
            SizedBox(width: 12),
            Text('Password Reset', style: TextStyle(color: Colors.white)),
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
            child: const Text('OK', style: TextStyle(color: Color(0xFF00F5D4))),
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
      await LoginSuccessModal.show(
        context,
        email: _emailController.text.trim(),
        isBiometric: false,
      );
    } else {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _onBiometricPressed() async {
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();

    // Guard: biometric login requires an existing saved account
    if (!authVM.hasStoredCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No saved account found. Sign in with your password first.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isBiometricLoading = true);
    final success = await authVM.loginWithBiometrics();
    if (!mounted) return;
    setState(() => _isBiometricLoading = false);
    if (success) {
      await LoginSuccessModal.show(context, isBiometric: true);
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
  const _OrbPainter(this.t);

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
