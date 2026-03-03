import 'dart:math';
import 'package:flutter/foundation.dart';

class OTPService {
  String _generatedOTP = '';

  String generateOTP() {
    final random = Random();
    _generatedOTP = (random.nextInt(900000) + 100000).toString();
    debugPrint('SIMULATED OTP: $_generatedOTP');
    return _generatedOTP;
  }

  bool verifyOTP(String code) {
    return code.trim() == _generatedOTP.trim();
  }

  String get currentOTP => _generatedOTP;

  void clearOTP() {
    _generatedOTP = '';
  }
}
