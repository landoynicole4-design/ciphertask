import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// SessionService — Inactivity Timer & Auto-Logout (M3)
///
/// This service tracks user inactivity. If the user does NOT interact
/// with the app for [AppConstants.sessionTimeoutSeconds] (2 minutes),
/// it triggers an automatic logout/lock.
///
/// HOW IT WORKS:
///   - A [Timer] is started when the user logs in.
///   - The timer is RESET every time the user touches the screen.
///     (A Listener widget in main.dart calls resetTimer() on every pointer event)
///   - If the timer expires without being reset → onTimeout() fires.
///   - onTimeout() navigates the user back to the Login screen.
///
/// USAGE:
///   1. Call start(onTimeout) after successful login.
///   2. Call resetTimer() on every user interaction (handled in main.dart).
///   3. Call stop() on manual logout.
class SessionService {
  Timer? _inactivityTimer;

  // Callback that fires when session expires.
  // Set by the consumer (AuthViewModel) to define what "logout" means.
  VoidCallback? onTimeout;

  /// Starts the inactivity timer.
  ///
  /// [onTimeout] will be called if the user is idle for the full duration.
  void start({required VoidCallback onTimeout}) {
    this.onTimeout = onTimeout;
    _startTimer();
  }

  /// Resets the timer back to the full duration.
  ///
  /// Called by the Listener widget in main.dart on every pointer/touch event.
  /// This is what keeps active users from being logged out.
  void resetTimer() {
    if (onTimeout == null) return; // Session not started yet
    _inactivityTimer?.cancel();
    _startTimer();
  }

  /// Stops the timer completely.
  ///
  /// Call this on manual logout so the timer doesn't fire unexpectedly.
  void stop() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    onTimeout = null;
  }

  /// Internal: Creates a new countdown timer.
  void _startTimer() {
    // Fixed: Duration constructor is now const
    _inactivityTimer = Timer(
      const Duration(seconds: AppConstants.sessionTimeoutSeconds),
      () {
        // Timer expired — trigger logout
        onTimeout?.call();
      },
    );
  }

  /// Whether the session timer is currently active.
  bool get isActive => _inactivityTimer?.isActive ?? false;
}
