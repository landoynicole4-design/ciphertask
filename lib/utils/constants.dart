/// App-wide constants for CipherTask.
///
/// Centralizing these values makes it easy to change timeouts,
/// key names, and box names without hunting through the codebase.
class AppConstants {
  // ─── Session ────────────────────────────────────────────────
  /// Auto-logout after 2 minutes of inactivity (in seconds)
  static const int sessionTimeoutSeconds = 120;

  // ─── Secure Storage Keys ────────────────────────────────────
  /// Key name used to store/retrieve the Hive DB encryption key
  static const String hiveEncryptionKeyName = 'hive_encryption_key';

  /// Key name used to store/retrieve the AES-256 secret key
  static const String aesSecretKeyName = 'aes_secret_key';

  /// Key name for the AES initialization vector (IV)
  static const String aesIvKeyName = 'aes_iv_key';

  /// Stores whether biometric login is enabled for this user
  static const String biometricEnabledKey = 'biometric_enabled';

  /// Stores whether user has completed first password login
  static const String hasLoggedInOnceKey = 'has_logged_in_once';

  /// Stores the current logged-in user's email for biometric login
  static const String currentUserEmailKey = 'current_user_email';

  // ─── Hive Box Names ─────────────────────────────────────────
  /// Name of the encrypted Hive box that stores To-Do items
  static const String todoBoxName = 'secure_todos';

  // ─── Routes ─────────────────────────────────────────────────
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String todoListRoute = '/todos';

  // ─── Regex Validation Patterns (Security) ───────────────────
  /// Email validation regex (RFC 5322 simplified)
  /// Validates: user@domain.com format
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  /// Password validation regex (Secure Password Requirements)
  /// Requirements:
  /// - At least 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 digit
  /// - At least 1 special character (!@#$%^&*()_+-=)
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=-]).{8,}$',
  );

  /// Validation helper functions
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must contain:\n• 1 uppercase letter\n• 1 lowercase letter\n• 1 number\n• 1 special character (!@#\$%^&*)';
    }
    return null;
  }
}
