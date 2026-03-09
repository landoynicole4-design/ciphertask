import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

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
  final _scrollController = ScrollController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String _passwordText = '';

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;

  void _onPasswordChanged() {
    if (mounted) setState(() => _passwordText = _passwordController.text);
  }

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

    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  double _passwordStrength(String p) {
    if (p.isEmpty) return 0.0;
    double s = 0.0;
    if (p.length >= 8) s += 0.15;
    if (p.length >= 12) s += 0.15;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.175;
    if (p.contains(RegExp(r'[a-z]'))) s += 0.175;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.175;
    if (p.contains(RegExp(r'[^a-zA-Z0-9]'))) s += 0.175;
    return s.clamp(0.0, 1.0);
  }

  Color _strengthColor(double s) {
    if (s < 0.4) return const Color(0xFFFF4D6D);
    if (s < 0.7) return const Color(0xFFFFB547);
    return const Color(0xFF4ADE80);
  }

  String _strengthLabel(double s) {
    if (s < 0.4) return 'Weak';
    if (s < 0.65) return 'Moderate';
    if (s < 0.85) return 'Strong';
    return 'Very Strong';
  }

  bool _req(String pattern) => _passwordText.contains(RegExp(pattern));

  bool get _allMet =>
      _passwordText.length >= 8 &&
      _req(r'[A-Z]') &&
      _req(r'[a-z]') &&
      _req(r'[0-9]') &&
      _req(r'[^a-zA-Z0-9]');

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      resizeToAvoidBottomInset: false,
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
                    child: AutofillGroup(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: isSmallScreen ? 8 : 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLogoHeader(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 12 : 18),
                            _buildForm(authVM, isSmallScreen),
                            const SizedBox(height: 16),
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

  Widget _buildLogoHeader(bool isSmallScreen) {
    final logoSize = isSmallScreen ? 48.0 : 58.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                  center: Alignment.topLeft,
                  radius: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.shield_rounded,
                  color: Colors.white, size: logoSize * 0.48),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                'CipherTask',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CREATE YOUR SECURE ACCOUNT',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 1.2),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF6B7280), size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthViewModel authVM, bool isSmallScreen) {
    final strength = _passwordStrength(_passwordText);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Security badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.25),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Color(0xFF7B61FF), size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'End-to-end encrypted  ·  AES-256',
                      style: TextStyle(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 14 : 18),

            // Email
            _buildInputField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              validator: AppConstants.validateEmail,
            ),
            const SizedBox(height: 12),

            // Password
            _buildInputField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Password is required';
                if (value.length < 8) return 'Must be at least 8 characters';
                if (!value.contains(RegExp(r'[A-Z]')))
                  return 'Add one uppercase letter';
                if (!value.contains(RegExp(r'[a-z]')))
                  return 'Add one lowercase letter';
                if (!value.contains(RegExp(r'[0-9]'))) return 'Add one number';
                if (!value.contains(RegExp(r'[^a-zA-Z0-9]')))
                  return 'Add one special character';
                return null;
              },
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
            ),

            // ── Strength bar — always same height, no layout shift ──
            const SizedBox(height: 10),
            _buildStrengthSection(strength),
            const SizedBox(height: 12),

            // Confirm password
            _buildConfirmField(),

            const SizedBox(height: 16),

            // Auth error
            if (authVM.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: authVM.clearError,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFFFF4D6D).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF4D6D), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(authVM.errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFFF4D6D), fontSize: 12)),
                        ),
                        const Icon(Icons.close_rounded,
                            color: Color(0xFFFF4D6D), size: 14),
                      ],
                    ),
                  ),
                ),
              ),

            _buildTermsCheckbox(),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildCreateAccountButton(authVM),
          ],
        ),
      ),
    );
  }

  // ── Strength bar: ALWAYS renders at the same height.
  // Requirements are always present — met ones turn green, unmet stay dim.
  // Nothing ever appears or disappears so the layout never shifts.
  Widget _buildStrengthSection(double strength) {
    final isEmpty = _passwordText.isEmpty;

    final reqs = [
      {'label': '8+ characters', 'met': _passwordText.length >= 8},
      {'label': 'Uppercase', 'met': _req(r'[A-Z]')},
      {'label': 'Lowercase', 'met': _req(r'[a-z]')},
      {'label': 'Number', 'met': _req(r'[0-9]')},
      {'label': 'Special char', 'met': _req(r'[^a-zA-Z0-9]')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar row
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isEmpty ? 0.0 : strength,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEmpty ? Colors.transparent : _strengthColor(strength),
                  ),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(
                isEmpty
                    ? ''
                    : _allMet
                        ? '✓ ${_strengthLabel(strength)}'
                        : _strengthLabel(strength),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isEmpty
                      ? Colors.transparent
                      : _allMet
                          ? const Color(0xFF4ADE80)
                          : _strengthColor(strength),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Requirements chips — always rendered, never removed
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: reqs.map((r) {
            final met = r['met'] as bool;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  met
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 11,
                  color: met
                      ? const Color(0xFF4ADE80)
                      : Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 3),
                Text(
                  r['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: met
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.25),
                    fontWeight: met ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmFocus,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
      enableInteractiveSelection: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.lock_outline_rounded,
              color: Color(0xFF00F5D4), size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
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
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'Please confirm your password';
        if (value != _passwordText) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    List<String>? autofillHints,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      enableInteractiveSelection: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF00F5D4), size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
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
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _agreedToTerms
                      ? const Color(0xFF00F5D4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _agreedToTerms
                        ? const Color(0xFF00F5D4)
                        : const Color(0xFF6B7280),
                    width: 1.5,
                  ),
                ),
                child: _agreedToTerms
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF050810), size: 13)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: _showTermsModal,
                    child: const Text('Terms',
                        style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF00F5D4))),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: _showTermsModal,
                    child: const Text('Privacy Policy',
                        style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF00F5D4))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(AuthViewModel authVM) {
    final isLoading = authVM.isLoading;
    return GestureDetector(
      onTapDown: (_) {
        if (!isLoading) _buttonPressController.forward();
      },
      onTapUp: (_) {
        _buttonPressController.reverse();
        if (!isLoading) _onRegisterPressed();
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
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B61FF), Color(0xFF00F5D4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: _agreedToTerms && !isLoading
                ? [
                    BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          foregroundDecoration: !_agreedToTerms
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withValues(alpha: 0.35))
              : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: _agreedToTerms ? 1.0 : 0.5),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white
                              .withValues(alpha: _agreedToTerms ? 1.0 : 0.5),
                          size: 17),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Sign In',
              style: TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Terms of Service',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text(
                  '• By using CipherTask, you agree to use the app responsibly.\n'
                  '• You are responsible for maintaining the security of your account.\n'
                  '• All data is encrypted locally on your device.\n'
                  '• We do not store or transmit your passwords or sensitive data.\n'
                  '• You must be at least 13 years of age to use this app.',
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                const Text('Privacy Policy',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text(
                  '• CipherTask stores all data locally on your device.\n'
                  '• Your passwords are hashed using SHA-256.\n'
                  '• Sensitive notes are encrypted with AES-256.\n'
                  '• The app does not collect, transmit, or share any personal data.\n'
                  '• Biometric authentication data stays on your device only.\n'
                  '• We have no access to your encrypted data.',
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () {
                    if (mounted) setState(() => _agreedToTerms = true);
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: const Center(
                      child: Text('I Understand',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onRegisterPressed() {
    FocusScope.of(context).unfocus();

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
                child: Text('Please agree to the Terms of Service first.')),
          ]),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authVM = context.read<AuthViewModel>();
    authVM.sendOtp(email, password);
    Navigator.pushNamed(context, AppConstants.otpRoute);
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
    final c1 = Offset(size.width * 0.85 + math.cos(a1) * 40,
        size.height * 0.15 + math.sin(a1) * 30);
    canvas.drawCircle(
        c1,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.25),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c1, radius: 200)));

    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.15 + math.cos(a2) * 50,
        size.height * 0.8 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.2),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c2, radius: 220)));

    final a3 = t * 2 * math.pi * 0.6;
    final c3 = Offset(size.width * 0.5 + math.cos(a3) * 30,
        size.height * 0.5 + math.sin(a3) * 30);
    canvas.drawCircle(
        c3,
        160,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF4F6EF7).withValues(alpha: 0.12),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c3, radius: 160)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
