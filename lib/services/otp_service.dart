import 'dart:math';
import 'package:flutter/foundation.dart';

/// OTPService — One-Time Password Generator
///
/// Generates a 6-digit OTP for email verification during registration.
/// Uses [Random.secure()] — a cryptographically secure random number
/// generator backed by the OS entropy pool (instead of a predictable
/// pseudo-random generator). This prevents OTP prediction attacks.
class OTPService {
  String _generatedOTP = '';
  DateTime? _otpGeneratedAt;
  static const int _otpValiditySeconds = 300; // 5 minutes

  String generateOTP() {
    final random = Random.secure();
    _generatedOTP = (random.nextInt(900000) + 100000).toString();
    _otpGeneratedAt = DateTime.now();
    debugPrint('🔐 SIMULATED OTP (debug only): $_generatedOTP');
    return _generatedOTP;
  }

  bool verifyOTP(String code) {
    if (_generatedOTP.isEmpty) return false;
    if (_otpGeneratedAt != null) {
      final elapsed = DateTime.now().difference(_otpGeneratedAt!).inSeconds;
      if (elapsed > _otpValiditySeconds) {
        debugPrint('⚠️ OTP expired after $_otpValiditySeconds seconds');
        return false;
      }
    }
    return code.trim() == _generatedOTP.trim();
  }

  bool get isOtpValid {
    if (_generatedOTP.isEmpty || _otpGeneratedAt == null) return false;
    final elapsed = DateTime.now().difference(_otpGeneratedAt!).inSeconds;
    return elapsed <= _otpValiditySeconds;
  }

  int get secondsRemaining {
    if (_otpGeneratedAt == null) return 0;
    final elapsed = DateTime.now().difference(_otpGeneratedAt!).inSeconds;
    return (_otpValiditySeconds - elapsed).clamp(0, _otpValiditySeconds);
  }

  String get currentOTP => _generatedOTP;

  void clearOTP() {
    _generatedOTP = '';
    _otpGeneratedAt = null;
  }
}
