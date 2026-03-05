import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showOtpField = false;
  bool _agreedToTerms = false;

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  double _passwordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.20;
    return strength.clamp(0.0, 1.0);
  }

  Color _strengthColor(double strength) {
    if (strength < 0.4) return const Color(0xFFFF4D6D);
    if (strength < 0.7) return const Color(0xFFFFB547);
    return const Color(0xFF4ADE80);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;

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
                        vertical: isSmallScreen ? 12 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBackButton(context),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildHeader(authVM),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _showOtpField
                                ? _buildOtpSection(authVM, isSmallScreen)
                                : _buildRegistrationForm(authVM, isSmallScreen),
                          ),
                          // Dynamic bottom spacing when keyboard is visible
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: hasKeyboard
                                ? (keyboardHeight * 0.2).clamp(16.0, 40.0)
                                : 0,
                          ),
                        ],
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

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF6B7280),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthViewModel authVM) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _showOtpField ? 'Verify Your Account' : 'Create Your Secure Account',
        key: ValueKey(_showOtpField),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(AuthViewModel authVM, bool isSmallScreen) {
    final passwordStrength = _passwordStrength(_passwordController.text);
    return Container(
      key: const ValueKey('registration-form'),
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
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed: Made the security badge responsive
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      color: Color(0xFF7B61FF), size: 14),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'End-to-end encrypted',
                      style: TextStyle(
                          color: Color(0xFF7B61FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '•',
                    style: TextStyle(color: Color(0xFF7B61FF), fontSize: 12),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'AES-256',
                      style: TextStyle(
                          color: Color(0xFF7B61FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AppConstants.validatePassword,
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
              onChanged: (_) => setState(() {}),
              isSmallScreen: isSmallScreen,
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrengthBar(passwordStrength),
            ],
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildInputField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey(_obscureConfirm),
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              // Fixed: Added null check for confirm password validator
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
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
            _buildTermsCheckbox(),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCreateAccountButton(authVM),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(double strength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_strengthColor(strength)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength < 0.4
                  ? 'Weak'
                  : strength < 0.7
                      ? 'Moderate'
                      : 'Strong',
              style: TextStyle(
                color: _strengthColor(strength),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color:
                  _agreedToTerms ? const Color(0xFF00F5D4) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreedToTerms
                    ? const Color(0xFF00F5D4)
                    : const Color(0xFF6B7280),
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded,
                    color: Color(0xFF050810), size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _showTermsModal,
                      child: const Text(
                        'Terms',
                        style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _showTermsModal,
                      child: const Text(
                        'Privacy',
                        style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(AuthViewModel authVM) {
    final isDisabled = authVM.isLoading || !_agreedToTerms;
    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          _buttonPressController.forward();
        }
      },
      onTapUp: (_) {
        _buttonPressController.reverse();
        if (!isDisabled) {
          _onRegisterPressed();
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
                    colors: [Color(0xFF7B61FF), Color(0xFF00F5D4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
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
                      Text('Create Account',
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

  Widget _buildOtpSection(AuthViewModel authVM, bool isSmallScreen) {
    return Container(
      key: const ValueKey('otp-section'),
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
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOtpEmailSection(authVM, isSmallScreen),
          SizedBox(height: isSmallScreen ? 16 : 24),
          _buildOtpInputSection(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildOtpSimulationBox(authVM),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildOtpErrorMessage(authVM),
          _buildResendRow(authVM),
        ],
      ),
    );
  }

  Widget _buildOtpEmailSection(AuthViewModel authVM, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF00F5D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: isSmallScreen ? 30 : 40),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          authVM.pendingEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF00F5D4),
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        const Text(
          'Enter the 6-digit code',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final hasKeyboard = keyboardHeight > 0;

        // Responsive sizing based on screen width
        final maxWidth = constraints.maxWidth;
        const itemCount = 6;
        final totalSpacing = (itemCount - 1) * 8.0; // 8dp gap between items
        final availableWidth = maxWidth - 16.0; // 8dp padding on each side
        final itemWidth = (availableWidth - totalSpacing) / itemCount;
        final constrainedWidth = itemWidth.clamp(28.0, 50.0);

        return SingleChildScrollView(
          reverse: hasKeyboard,
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: hasKeyboard ? keyboardHeight * 0.3 : 0,
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: List.generate(
                    6,
                    (index) => _buildOtpInputField(index, constrainedWidth),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpInputField(int index, double width) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_otpFocusNodes[index], _otpControllers[index]]),
      builder: (context, child) {
        final isFocused = _otpFocusNodes[index].hasFocus;
        final hasValue = _otpControllers[index].text.isNotEmpty;

        return SizedBox(
          width: width,
          height: width + 10,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: isFocused
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasValue
                      ? const Color(0xFF00F5D4).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF00F5D4), width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFF4D6D), width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFF4D6D), width: 1.8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                // Move to next field if available
                if (index < 5) {
                  _otpFocusNodes[index + 1].requestFocus();
                } else {
                  // Last field - verify OTP automatically
                  if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                    Future.delayed(
                        const Duration(milliseconds: 100), _verifyOtp);
                  }
                }
              }
            },
            onFieldSubmitted: (value) {
              if (index < 5 && value.isNotEmpty) {
                _otpFocusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildOtpErrorMessage(AuthViewModel authVM) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: authVM.errorMessage != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => context.read<AuthViewModel>().clearError(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const Icon(Icons.close_rounded,
                          color: Color(0xFFFF4D6D), size: 16),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildOtpInputs(bool isSmallScreen) {
    // This method is now replaced by _buildOtpInputSection
    return const SizedBox.shrink();
  }

  Widget _buildOtpSimulationBox(AuthViewModel authVM) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB547).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFFB547).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science_outlined, color: Color(0xFFFFB547), size: 16),
              SizedBox(width: 8),
              Text(
                'SIMULATED OTP',
                style: TextStyle(
                    color: Color(0xFFFFB547),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            authVM.currentOtp,
            style: const TextStyle(
                color: Color(0xFFFFB547),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildResendRow(AuthViewModel authVM) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive it? ",
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: authVM.showResendButton
              ? GestureDetector(
                  key: const ValueKey('resend-button'),
                  onTap: () => authVM.resendOtp(),
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                )
              : authVM.isResending
                  ? const SizedBox(
                      key: ValueKey('resend-loading'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF00F5D4)),
                    )
                  : Text(
                      key: const ValueKey('resend-timer'),
                      'in ${authVM.resendTimer}s',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 14),
                    ),
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
    void Function(String)? onChanged,
    bool isSmallScreen = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
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

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scrollController) {
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
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
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
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
                    setState(() => _agreedToTerms = true);
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'I Understand',
                        style: TextStyle(
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
      ),
    );
  }

  void _onRegisterPressed() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Please agree to the Terms of Service'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }
    final authVM = context.read<AuthViewModel>();
    authVM.sendOtp(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() {
      _showOtpField = true;
    });
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    final authVM = context.read<AuthViewModel>();

    // Add a small delay to ensure all fields are filled
    await Future.delayed(const Duration(milliseconds: 100));

    final success = await authVM.verifyOtp(code);
    if (!mounted) return;
    if (success) {
      _showWelcomeModal();
    } else {
      _shakeAnimation();
      _clearOtpFields();
    }
  }

  void _shakeAnimation() {
    _shakeController.forward(from: 0);
  }

  void _showWelcomeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to CipherTask!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your secure vault is ready',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(dialogCtx);
                Navigator.pushReplacementNamed(
                    context, AppConstants.todoListRoute);
              },
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Start Securing Tasks',
                    style: TextStyle(
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
    );
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
            Colors.transparent
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
            Colors.transparent
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
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c3, radius: 160)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
