import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';
import '../services/otp_service.dart';
import '../utils/constants.dart';

/// AuthViewModel — Authentication State Manager
/// Handles all auth logic: password login, biometric unlock, registration,
/// session timeout, and logout.
class AuthViewModel extends ChangeNotifier {
  final LocalAuthentication _localAuth;
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;

  // Local Hive box for user storage
  static const String _usersBoxName = 'users';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  Box? _usersBox;

  // OTP State
  final OTPService _otpService = OTPService();
  bool _otpSent = false;
  bool _isVerified = false;
  String _pendingEmail = '';
  String _pendingPassword = '';
  int _resendTimer = 30;
  bool _showResendButton = false;
  bool _isResending = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get otpSent => _otpSent;
  bool get isVerified => _isVerified;
  int get resendTimer => _resendTimer;
  bool get showResendButton => _showResendButton;
  bool get isResending => _isResending;
  String get pendingEmail => _pendingEmail;
  String get currentOtp => _otpService.currentOTP;

  AuthViewModel({
    required LocalAuthentication localAuth,
    required KeyStorageService keyStorage,
    required SessionService sessionService,
  })  : _localAuth = localAuth,
        _keyStorage = keyStorage,
        _sessionService = sessionService {
    _initUsersBox();
  }

  Future<void> _initUsersBox() async {
    _usersBox = await Hive.openBox(_usersBoxName);
  }

  /// Register a new user locally
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    try {
      if (_usersBox == null) {
        await _initUsersBox();
      }

      // Check if email already exists
      final existingUser = _usersBox!.get(email.toLowerCase());
      if (existingUser != null) {
        _errorMessage = 'An account with this email already exists.';
        notifyListeners();
        return false;
      }

      // Hash password for storage
      final hashedPassword = _hashPassword(password);

      // Create and store user
      final user = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email.toLowerCase(),
        passwordHash: hashedPassword,
        isEmailVerified: true,
      );

      await _usersBox!.put(email.toLowerCase(), user.toJson());

      // Mark first login complete
      await _keyStorage.storeKey(AppConstants.hasLoggedInOnceKey, 'true');
      await _keyStorage.storeKey(
          AppConstants.currentUserEmailKey, email.toLowerCase());

      _currentUser = user;
      _startSession();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<bool> loginWithPassword(String email, String password) async {
    _setLoading(true);
    try {
      if (_usersBox == null) {
        await _initUsersBox();
      }

      final emailLower = email.toLowerCase();
      final userJson = _usersBox!.get(emailLower);

      if (userJson == null) {
        _errorMessage = 'No account found with this email.';
        notifyListeners();
        return false;
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      final hashedInput = _hashPassword(password);

      if (user.passwordHash != hashedInput) {
        _errorMessage = 'Incorrect password. Please try again.';
        notifyListeners();
        return false;
      }

      _currentUser = user;

      // Mark first login complete
      await _keyStorage.storeKey(AppConstants.hasLoggedInOnceKey, 'true');
      await _keyStorage.storeKey(AppConstants.currentUserEmailKey, emailLower);

      _startSession();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if biometrics are available
  Future<bool> canUseBiometrics() async {
    final hasLoggedInOnce =
        await _keyStorage.retrieveKey(AppConstants.hasLoggedInOnceKey);
    if (hasLoggedInOnce != 'true') return false;

    final isDeviceSupported = await _localAuth.isDeviceSupported();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    return isDeviceSupported && canCheckBiometrics;
  }

  /// Check if Face ID is available (specifically)
  Future<bool> canUseFaceId() async {
    final hasLoggedInOnce =
        await _keyStorage.retrieveKey(AppConstants.hasLoggedInOnceKey);
    if (hasLoggedInOnce != 'true') return false;

    final isDeviceSupported = await _localAuth.isDeviceSupported();
    if (!isDeviceSupported) return false;

    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.face);
  }

  /// Check which biometric types are available
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  /// Login with biometrics
  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    try {
      if (_usersBox == null) {
        await _initUsersBox();
      }

      // Prompt biometric dialog
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock CipherTask with your biometric',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        _errorMessage = 'Biometric authentication failed.';
        notifyListeners();
        return false;
      }

      // Restore user from local storage
      final savedEmail =
          await _keyStorage.retrieveKey(AppConstants.currentUserEmailKey);
      if (savedEmail == null) {
        _errorMessage =
            'No saved user found. Please log in with your password first.';
        notifyListeners();
        return false;
      }

      final userJson = _usersBox!.get(savedEmail);
      if (userJson == null) {
        _errorMessage =
            'User data not found. Please log in with your password.';
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromJson(Map<String, dynamic>.from(userJson));

      _startSession();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Biometric error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _sessionService.stop();
    _currentUser = null;
    _errorMessage = null;
    // Clear OTP state on logout
    _otpSent = false;
    _isVerified = false;
    _pendingEmail = '';
    _pendingPassword = '';
    _showResendButton = false;
    _resendTimer = 30;
    _otpService.clearOTP();
    notifyListeners();
  }

  /// Called on user activity
  void onUserActivity() {
    _sessionService.resetTimer();
  }

  /// Start session timer
  void _startSession() {
    _sessionService.start(
      onTimeout: () async {
        await logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(AppConstants.loginRoute, (_) => false);
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Send OTP to the given contact (email)
  void sendOtp(String email, String password) {
    _pendingEmail = email;
    _pendingPassword = password;
    _otpService.generateOTP();
    _otpSent = true;
    _isVerified = false;
    _startResendTimer();
    notifyListeners();
  }

  /// Verify the entered OTP
  Future<bool> verifyOtp(String code) async {
    final isValid = _otpService.verifyOTP(code);
    if (isValid) {
      _isVerified = true;
      notifyListeners();
      // Proceed with registration
      final success = await register(_pendingEmail, _pendingPassword);
      return success;
    } else {
      _errorMessage = 'Invalid OTP. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Reset OTP state
  void resetOtp() {
    _otpSent = false;
    _isVerified = false;
    _pendingEmail = '';
    _pendingPassword = '';
    _showResendButton = false;
    _resendTimer = 30;
    _otpService.clearOTP();
    notifyListeners();
  }

  /// Start the resend timer
  void _startResendTimer() {
    _showResendButton = false;
    _resendTimer = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_otpSent) {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _showResendButton = true;
          notifyListeners();
          return false;
        }
        notifyListeners();
        return true;
      }
      return false;
    });
  }

  /// Resend OTP
  void resendOtp() {
    _isResending = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      _otpService.generateOTP();
      _isResending = false;
      _startResendTimer();
      notifyListeners();
    });
  }
}
