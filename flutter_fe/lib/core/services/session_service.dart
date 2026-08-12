import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/auth_local_datasource.dart';
import '../../presentation/auth/pages/login_screen.dart';

/// Global service to handle session expiration (401 Unauthorized).
/// Clears local data and navigates to login screen.
///
/// Design note: `_isHandlingSessionExpired` is intentionally NOT reset in the
/// finally block. It stays `true` until [reset] is explicitly called (i.e., on
/// successful login). This prevents rapid-fire 401 responses from multiple
/// concurrent API calls from re-triggering logout while the user is already
/// on the LoginScreen.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  static SessionService get instance => _instance;

  SessionService._internal();

  /// Global navigator key for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isHandlingSessionExpired = false;

  /// Handle 401 Unauthorized response.
  /// Clears all local data and redirects to login screen.
  /// Subsequent calls are no-op until [reset] is called after a successful login.
  Future<void> handleSessionExpired() async {
    // Guard: if already handling (or already redirected to login), skip.
    // Flag is reset only on successful login via reset(), not in finally.
    if (_isHandlingSessionExpired) return;
    _isHandlingSessionExpired = true;

    try {
      // Clear all local auth data
      final authLocal = AuthLocalDatasource();
      await authLocal.removeAuthData();

      // Navigate to login screen and clear navigation stack
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      // On unexpected error, reset flag so the next call can retry.
      _isHandlingSessionExpired = false;
    }
    // Intentionally NOT resetting flag here — see class doc above.
  }

  /// Check if response is 401 and handle session expiration.
  /// Returns true if it was a 401 response (session expired).
  bool checkAndHandle401(http.Response response) {
    if (response.statusCode == 401) {
      handleSessionExpired();
      return true;
    }
    return false;
  }

  /// Check if streamed response is 401 and handle session expiration.
  /// Returns true if it was a 401 response (session expired).
  bool checkAndHandle401Streamed(http.StreamedResponse response) {
    if (response.statusCode == 401) {
      handleSessionExpired();
      return true;
    }
    return false;
  }

  /// Reset the session-expired flag. MUST be called after a successful login
  /// so that future 401 responses can trigger logout again if needed.
  void reset() {
    _isHandlingSessionExpired = false;
  }
}
