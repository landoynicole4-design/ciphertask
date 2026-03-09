import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paste / SMS-autofill formatter
// ─────────────────────────────────────────────────────────────────────────────
class _OtpPasteFormatter extends TextInputFormatter {
  final int fieldIndex;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onComplete;

  const _OtpPasteFormatter({
    required this.fieldIndex,
    required this.controllers,
    required this.focusNodes,
    required this.onComplete,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (text.length > 1) {
      final digits = text.substring(0, math.min(6, text.length));
      for (int i = 0; i < digits.length && i < controllers.length; i++) {
        controllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        Future.microtask(onComplete);
      } else {
        final nextIndex = math.min(digits.length, controllers.length - 1);
        Future.microtask(() => focusNodes[nextIndex].requestFocus());
      }
      final myDigit = digits.isNotEmpty ? digits[0] : '';
      return TextEditingValue(
        text: myDigit,
        selection: TextSelection.collapsed(offset: myDigit.length),
      );
    }

    if (text.isEmpty) return newValue.copyWith(text: '');
    return newValue.copyWith(
      text: text[0],
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP Field — NO listeners at all.
// Flutter handles focus border natively via focusedBorder.
// onChanged handles fill color + focus movement safely.
// ─────────────────────────────────────────────────────────────────────────────
class _OtpField extends StatefulWidget {
  final int index;
  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<TextEditingController> allControllers;
  final List<FocusNode> allFocusNodes;
  final VoidCallback onComplete;
  final VoidCallback onAnyChange;

  const _OtpField({
    required this.index,
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.allControllers,
    required this.allFocusNodes,
    required this.onComplete,
    required this.onAnyChange,
  });

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  // Track filled state locally — updated ONLY via onChanged (safe)
  bool _isFilled = false;

  @override
  void initState() {
    super.initState();
    _isFilled = widget.controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + 8,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty &&
              widget.index > 0) {
            widget.allControllers[widget.index - 1].clear();
            widget.allFocusNodes[widget.index - 1].requestFocus();
            // Notify parent so verify button updates
            widget.onAnyChange();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [
            _OtpPasteFormatter(
              fieldIndex: widget.index,
              controllers: widget.allControllers,
              focusNodes: widget.allFocusNodes,
              onComplete: widget.onComplete,
            ),
          ],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            // Fill color based on local _isFilled — no listener needed
            fillColor: _isFilled
                ? const Color(0xFF00F5D4).withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.07),
            // Flutter handles focusedBorder automatically — no listener needed
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _isFilled
                    ? const Color(0xFF00F5D4).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: _isFilled ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF00F5D4),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            // setState only inside this tiny widget — safe, no page rebuild
            if (mounted) {
              setState(() => _isFilled = value.isNotEmpty);
            }
            if (value.isNotEmpty) {
              if (widget.index < 5) {
                widget.allFocusNodes[widget.index + 1].requestFocus();
              } else {
                FocusScope.of(context).unfocus();
                Future.delayed(const Duration(milliseconds: 150), () {
                  widget.onComplete();
                });
              }
            }
            // Tell parent to refresh verify button
            widget.onAnyChange();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main OTP View
// ─────────────────────────────────────────────────────────────────────────────
class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late AnimationController _emailCardController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;
  late Animation<Offset> _emailCardSlideAnim;
  late Animation<double> _emailCardFadeAnim;

  bool _isVerifying = false;
  bool _emailCardVisible = true;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _emailCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _emailCardSlideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _emailCardController, curve: Curves.easeOutBack));
    _emailCardFadeAnim =
        CurvedAnimation(parent: _emailCardController, curve: Curves.easeOut);

    _fadeController.forward();
    _slideController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _emailCardController.forward();
    });

    Future.delayed(const Duration(milliseconds: 6800), () {
      if (mounted) _dismissEmailCard();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _otpFocusNodes) node.dispose();
    for (final c in _otpControllers) c.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _emailCardController.dispose();
    super.dispose();
  }

  void _clearOtpFields() {
    for (final c in _otpControllers) c.clear();
    if (mounted) {
      setState(() {});
      _otpFocusNodes[0].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _isVerifying = true);

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.verifyOtp(code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (success) {
      _showWelcomeModal();
    } else {
      _shakeController.reset();
      _shakeController.forward();
      _clearOtpFields();
    }
  }

  void _dismissEmailCard() {
    if (!mounted || !_emailCardVisible) return;
    _emailCardController.reverse().then((_) {
      if (mounted) setState(() => _emailCardVisible = false);
    });
  }

  void _autoFillOtp(String otp) {
    if (otp.length != 6) return;
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = otp[i];
      }
      setState(() {});
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && !_isVerifying) _verifyOtp();
      });
    });
  }

  void _showWelcomeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            const Text('Welcome to CipherTask!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Your secure vault is ready',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
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
                  child: Text('Start Securing Tasks',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      // Let the scaffold handle keyboard insets natively
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
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: size.width > 400 ? 24 : 16,
                        right: size.width > 400 ? 24 : 16,
                        top: isSmallScreen ? 12 : 20,
                        // Pad bottom by keyboard height so fields aren't hidden
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBackButton(),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          _buildHeader(),
                          SizedBox(height: isSmallScreen ? 20 : 32),
                          _buildOtpCard(authVM, isSmallScreen),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_emailCardVisible)
            Consumer<AuthViewModel>(
              builder: (context, authVM, _) => _buildFloatingEmailCard(authVM),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingEmailCard(AuthViewModel authVM) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _emailCardSlideAnim,
        child: FadeTransition(
          opacity: _emailCardFadeAnim,
          child: GestureDetector(
            onTap: _dismissEmailCard,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -200) _dismissEmailCard();
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 32,
                      offset: const Offset(0, 12)),
                  BoxShadow(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F5D4), Color(0xFF7B61FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('CipherTask',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF6B7280),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('just now',
                                style: TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text('Your verification code',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildOtpCodeDisplay(authVM.currentOtp),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final otp = authVM.currentOtp;
                                Clipboard.setData(ClipboardData(text: otp));
                                _dismissEmailCard();
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () => _autoFillOtp(otp),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F5D4)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF00F5D4)
                                          .withValues(alpha: 0.3),
                                      width: 1),
                                ),
                                child: const Text('Copy',
                                    style: TextStyle(
                                        color: Color(0xFF00F5D4),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissEmailCard,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 16),
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

  Widget _buildOtpCodeDisplay(String otp) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: otp.split('').map((digit) {
          return Container(
            margin: const EdgeInsets.only(right: 3),
            width: 22,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
                  width: 1),
            ),
            child: Center(
              child: Text(digit,
                  style: const TextStyle(
                      color: Color(0xFF00F5D4),
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackButton() {
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
          child: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF6B7280), size: 18),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (_, __) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF00F5D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  blurRadius: 20 +
                      (math.sin(_bgAnimController.value * 2 * math.pi) * 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Verify Your Account',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('We sent a 6-digit code to your email',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
      ],
    );
  }

  Widget _buildOtpCard(AuthViewModel authVM, bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = math.sin(_shakeAnim.value * math.pi * 6) *
            10 *
            (1 - _shakeAnim.value);
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
            _buildEmailDisplay(authVM),
            SizedBox(height: isSmallScreen ? 20 : 28),
            const Text('Enter 6-Digit Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _buildOtpInputRow(),
            SizedBox(height: isSmallScreen ? 16 : 24),
            if (!_emailCardVisible)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    _emailCardController.reset();
                    setState(() => _emailCardVisible = true);
                    _emailCardController.forward();
                    Future.delayed(const Duration(seconds: 6), () {
                      if (mounted && _emailCardVisible) _dismissEmailCard();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF00F5D4).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Color(0xFF00F5D4), size: 15),
                        const SizedBox(width: 8),
                        Text('Tap to show your code again',
                            style: TextStyle(
                                color: const Color(0xFF00F5D4)
                                    .withValues(alpha: 0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            if (authVM.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: authVM.clearError,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
              ),
            _buildVerifyButton(authVM),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildResendRow(authVM),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailDisplay(AuthViewModel authVM) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00F5D4).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00F5D4).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alternate_email_rounded,
              color: Color(0xFF00F5D4), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              authVM.pendingEmail,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInputRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const itemCount = 6;
        const spacing = 8.0;
        const totalSpacing = spacing * (itemCount - 1);
        final itemSize = ((constraints.maxWidth - totalSpacing) / itemCount)
            .clamp(36.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index < 5 ? spacing : 0),
              child: _OtpField(
                index: index,
                size: itemSize,
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                allControllers: _otpControllers,
                allFocusNodes: _otpFocusNodes,
                onComplete: () {
                  if (!_isVerifying) _verifyOtp();
                },
                onAnyChange: () {
                  if (mounted) setState(() {});
                },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVerifyButton(AuthViewModel authVM) {
    final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
    final isDisabled = _isVerifying || authVM.isLoading || !allFilled;

    return GestureDetector(
      onTap: isDisabled ? null : _verifyOtp,
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
          child: (_isVerifying || authVM.isLoading)
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Verify Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResendRow(AuthViewModel authVM) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't receive it? ",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: authVM.showResendButton
              ? GestureDetector(
                  key: const ValueKey('resend-active'),
                  onTap: () {
                    authVM.resendOtp();
                    _clearOtpFields();
                    _emailCardController.reset();
                    setState(() => _emailCardVisible = true);
                    _emailCardController.forward();
                    Future.delayed(const Duration(seconds: 6), () {
                      if (mounted && _emailCardVisible) _dismissEmailCard();
                    });
                  },
                  child: const Text('Resend',
                      style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
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
            const Color(0xFF7B61FF).withValues(alpha: 0.22),
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
            const Color(0xFF4ADE80).withValues(alpha: 0.18),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 220)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
