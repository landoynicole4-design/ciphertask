import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

/// LoginView — Biometric & Password Login Screen (M5)
///
/// This screen is the entry point for returning users.
/// It supports two login methods:
///   1. Email + Password (always available)
///   2. Biometric (fingerprint/Face ID) — only if previously logged in once
///
/// MVVM Rule: This file contains ZERO business logic.
/// All decisions are delegated to AuthViewModel.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Check if biometrics are available — updates the UI accordingly
  Future<void> _checkBiometricAvailability() async {
    final authVM = context.read<AuthViewModel>();
    final canUse = await authVM.canUseBiometrics();
    if (mounted) {
      setState(() => _canUseBiometrics = canUse);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo & Title ──────────────────────────
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF4ECDC4),
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CipherTask',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'Secure Task Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 48),

                    // ── Email Field ───────────────────────────
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppConstants.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // ── Password Field ────────────────────────
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.key_outlined,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: AppConstants.validatePassword,
                    ),
                    const SizedBox(height: 28),

                    // ── Error Message ─────────────────────────
                    if (authVM.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Fixed: replaced deprecated withOpacity with withValues
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Text(
                          authVM.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Login Button ──────────────────────────
                    ElevatedButton(
                      onPressed: authVM.isLoading ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authVM.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // ── Biometric Login Button ─────────────────
                    if (_canUseBiometrics)
                      OutlinedButton.icon(
                        onPressed:
                            authVM.isLoading ? null : _onBiometricPressed,
                        icon: const Icon(Icons.fingerprint,
                            color: Color(0xFF4ECDC4)),
                        label: const Text(
                          'Unlock with Biometric',
                          style: TextStyle(color: Color(0xFF4ECDC4)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4ECDC4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── Register Link ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppConstants.registerRoute),
                          child: const Text('Register',
                              style: TextStyle(color: Color(0xFF4ECDC4))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Action Handlers ──────────────────────────────────────────

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    // Fixed: removed context argument — ViewModel uses navigatorKey internally
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
    // Fixed: removed context argument — ViewModel uses navigatorKey internally
    final success = await authVM.loginWithBiometrics();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
    }
  }

  // ─── Reusable Input Widget ────────────────────────────────────

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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF4ECDC4)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A2035),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }
}
