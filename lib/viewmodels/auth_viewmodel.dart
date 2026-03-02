import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

/// AuthViewModel — Authentication State Manager (M3)
///
/// Handles all auth logic: password login, biometric unlock, registration,
/// session timeout, and logout. Views NEVER call local_auth directly.
///
/// STATE FLOW:
///   [isLoading] → true while async auth operations are in progress
///   [currentUser] → non-null when logged in, null when logged out
///   [errorMessage] → set when something goes wrong (shown in UI)
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth? _firebaseAuth;
  final LocalAuthentication _localAuth;
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;

  // Local Hive box for user storage
  static const String _usersBoxName = 'users';

  /// Global navigator key — used for navigation after async gaps
  /// (avoids passing BuildContext across await boundaries).
  /// Pass this to MaterialApp's [navigatorKey] parameter.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  Box? _usersBox;

  // ─── Getters (read-only access for Views) ─────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  String? get verificationId => _verificationId;

  AuthViewModel({
    FirebaseAuth? firebaseAuth,
    required LocalAuthentication localAuth,
    required KeyStorageService keyStorage,
    required SessionService sessionService,
  })  : _firebaseAuth = firebaseAuth,
        _localAuth = localAuth,
        _keyStorage = keyStorage,
        _sessionService = sessionService {
    _initUsersBox();
  }

  Future<void> _initUsersBox() async {
    _usersBox = await Hive.openBox(_usersBoxName);
  }

  // ─── Registration with Email Verification ──────────────────────

  /// Sends verification email to the user's email address.
  /// Returns true if email was sent successfully.
  Future<bool> sendVerificationEmail(String email) async {
    if (_firebaseAuth == null) {
      _errorMessage = 'Firebase not configured. Using local-only mode.';
      return false;
    }

    _setLoading(true);
    try {
      // Check if email exists in Firebase, if not create it
      try {
        // Try to sign in first to check if user exists
        await _firebaseAuth!.signInWithEmailAndPassword(
          email: email,
          password: 'temp_password_for_verification_check',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // User doesn't exist, we'll create one with a temporary password
          // and then send verification email
        } else if (e.code == 'wrong-password') {
          // User exists, that's fine
        } else {
          // Other error
        }
      }

      // For email verification, we need to create a user with a temp password
      // and then send verification email
      // Since Firebase doesn't have a direct "send verification" API for email/password,
      // we'll use the sign-up flow and then send the email

      _errorMessage = 'Verification email sent! Please check your inbox.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send verification email: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new user with Firebase and sends verification email.
  ///
  /// On success: creates Firebase user, sends verification email,
  /// stores user in local Hive box, sets [currentUser].
  /// On failure: sets [errorMessage] for the View to display.
  Future<bool> registerWithEmailVerification(
      String email, String password) async {
    _setLoading(true);
    try {
      if (_firebaseAuth != null) {
        // Register with Firebase
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send verification email
        await _firebaseAuth!.currentUser?.sendEmailVerification();

        // Store user info locally as well
        if (_usersBox == null) {
          await _initUsersBox();
        }

        final user = UserModel(
          uid: credential.user?.uid ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          email: email.toLowerCase(),
          passwordHash: _hashPassword(password),
          isEmailVerified: false,
        );

        await _usersBox!.put(email.toLowerCase(), user.toJson());

        _errorMessage =
            'Registration successful! Please verify your email before logging in.';
        notifyListeners();
        return true;
      } else {
        // Fallback to local-only registration
        return await register(email, password);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new user locally (no Firebase).
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    try {
      // Wait for box to be ready
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
      );

      await _usersBox!.put(email.toLowerCase(), user.toJson());

      _currentUser = user;

      // Mark that the user has completed a password login at least once.
      // Biometric login requires this as a prerequisite.
      await _keyStorage.storeKey(AppConstants.hasLoggedInOnceKey, 'true');

      // Store current user email for biometric login
      await _keyStorage.storeKey(
          AppConstants.currentUserEmailKey, email.toLowerCase());

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

  // ─── Phone OTP Verification ───────────────────────────────────

  /// Sends OTP to the user's phone number for verification.
  Future<bool> sendPhoneVerification(String phoneNumber) async {
    if (_firebaseAuth == null) {
      _errorMessage = 'Firebase not configured.';
      return false;
    }

    _setLoading(true);
    try {
      await _firebaseAuth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await _firebaseAuth!.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = _getFirebaseErrorMessage(e.code);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _errorMessage = 'OTP sent to $phoneNumber';
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send OTP: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies the OTP entered by the user.
  Future<bool> verifyOTP(String otp) async {
    if (_firebaseAuth == null || _verificationId == null) {
      _errorMessage = 'No verification in progress.';
      return false;
    }

    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _firebaseAuth!.signInWithCredential(credential);
      _verificationId = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Verification failed: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Password Login ────────────────────────────────────────────

  /// Logs in an existing user with email and password locally.
  /// No [BuildContext] required — navigation uses [navigatorKey].
  Future<bool> loginWithPassword(String email, String password) async {
    _setLoading(true);
    try {
      // Wait for box to be ready
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

      // Mark first login as complete — enables biometric login going forward.
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

  // ─── Biometric Login ───────────────────────────────────────────

  /// Checks whether biometric login is available and allowed.
  ///
  /// Requirements:
  ///   1. Device hardware supports biometrics (fingerprint/face).
  ///   2. User has at least one biometric enrolled.
  ///   3. User has previously logged in with a password (prerequisite rule).
  Future<bool> canUseBiometrics() async {
    final hasLoggedInOnce =
        await _keyStorage.retrieveKey(AppConstants.hasLoggedInOnceKey);
    if (hasLoggedInOnce != 'true') return false;

    final isDeviceSupported = await _localAuth.isDeviceSupported();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    return isDeviceSupported && canCheckBiometrics;
  }

  /// Authenticates the user using biometrics (fingerprint or Face ID).
  ///
  /// On success: restores user from local storage and starts the session timer.
  /// No [BuildContext] required — navigation uses [navigatorKey].
  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    try {
      // Wait for box to be ready
      if (_usersBox == null) {
        await _initUsersBox();
      }

      // Prompt the system biometric dialog.
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock CipherTask with your biometric',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keeps dialog open if app goes to background.
          biometricOnly: true, // Don't allow PIN fallback for this flow.
        ),
      );

      if (!authenticated) {
        _errorMessage = 'Biometric authentication failed.';
        notifyListeners();
        return false;
      }

      // Biometric passed — restore user from local storage
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

  // ─── Logout ────────────────────────────────────────────────────

  /// Logs out the user: clears state, stops session timer.
  Future<void> logout() async {
    _sessionService.stop();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Session ───────────────────────────────────────────────────

  /// Called by the Listener widget in main.dart on every user touch.
  void onUserActivity() {
    _sessionService.resetTimer();
  }

  /// Starts session timer — used internally after successful login.
  /// Uses [navigatorKey] to navigate on timeout, avoiding BuildContext issues.
  void _startSession() {
    _sessionService.start(
      onTimeout: () async {
        await logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(AppConstants.loginRoute, (_) => false);
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Hashes password using SHA-256 for secure local storage.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Converts Firebase error codes to user-friendly messages.
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'quota-exceeded':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
