import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// OtpView — 6-Digit OTP Verification Screen (BONUS +5 pts) (M4)
///
/// This is a SIMULATED OTP screen. In a real app, the OTP would be sent
/// via email (Firebase Extensions) or SMS (Twilio/Firebase Phone Auth).
///
/// For this lab, the OTP is hardcoded/displayed for demo purposes.
/// The screen demonstrates the MFA flow required for the bonus points.
class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  // 6 controllers for 6 OTP digit boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // For demo: the "sent" OTP is shown on screen
  final String _simulatedOtp = '123456';
  bool _isVerifying = false;
  String? _errorMessage;

  // Countdown timer for OTP expiry (simulated 60 seconds)
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    // Fixed: wrapped for loop bodies in curly braces
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Icon & Title ──────────────────────────────
              const Icon(Icons.verified_user_outlined,
                  color: Color(0xFF4ECDC4), size: 72),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Identity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A 6-digit verification code was sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // ── Simulated OTP Display (Demo only) ─────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔐 Demo OTP: $_simulatedOtp (In production, this would be emailed/SMS\'d)',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF4ECDC4), fontSize: 12),
                ),
              ),
              const SizedBox(height: 36),

              // ── 6 OTP Input Boxes ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),
              const SizedBox(height: 20),

              // ── Timer ─────────────────────────────────────
              Text(
                _secondsRemaining > 0
                    ? 'Code expires in ${_secondsRemaining}s'
                    : 'Code expired. Please request a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondsRemaining > 0 ? Colors.grey : Colors.redAccent,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // ── Error Message ─────────────────────────────
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
              ],

              // ── Verify Button ─────────────────────────────
              ElevatedButton(
                onPressed: _isVerifying ? null : _onVerifyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // ── Resend ────────────────────────────────────
              TextButton(
                onPressed: _secondsRemaining == 0 ? _onResendPressed : null,
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    color: _secondsRemaining == 0
                        ? const Color(0xFF4ECDC4)
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF1A2035),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Auto-advance to next box
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            // Auto-back to previous box on delete
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  void _onVerifyPressed() async {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(seconds: 1));

    if (enteredOtp == _simulatedOtp) {
      // OTP correct — proceed to main app
      // Fixed: mounted check before using context across async gap
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
      }
    } else {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid code. Please try again.';
        _isVerifying = false;
        // Fixed: wrapped for loop body in curly braces
        for (final c in _controllers) {
          c.clear();
        }
      });
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  }

  void _onResendPressed() {
    // In a real app: re-trigger Firebase email/SMS
    setState(() {
      _secondsRemaining = 60;
      _errorMessage = null;
      // Fixed: wrapped for loop body in curly braces
      for (final c in _controllers) {
        c.clear();
      }
    });
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New OTP sent! (Demo: use 123456)')),
    );
  }
}
