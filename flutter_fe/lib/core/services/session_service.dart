import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/auth_local_datasource.dart';
import '../../presentation/auth/pages/login_screen.dart';

/// Global service to handle session expiration (401 Unauthorized)
/// Clears local data and navigates to login screen
class SessionService {
  static final SessionService _instance = SessionService._internal();
  static SessionService get instance => _instance;

  SessionService._internal();

  /// Global navigator key for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isHandlingSessionExpired = false;

  /// Handle 401 Unauthorized response
  /// Clears all local data and redirects to login screen
  Future<void> handleSessionExpired() async {
    // Prevent multiple simultaneous session expired handlers
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
    } finally {
      _isHandlingSessionExpired = false;
    }
  }

  /// Check if response is 401 and handle session expiration
  /// Returns true if it was a 401 response (session expired)
  bool checkAndHandle401(http.Response response) {
    if (response.statusCode == 401) {
      handleSessionExpired();
      return true;
    }
    return false;
  }

  /// Check if streamed response is 401 and handle session expiration
  /// Returns true if it was a 401 response (session expired)
  bool checkAndHandle401Streamed(http.StreamedResponse response) {
    if (response.statusCode == 401) {
      handleSessionExpired();
      return true;
    }
    return false;
  }

  /// Reset the handler state (useful for testing)
  void reset() {
    _isHandlingSessionExpired = false;
  }
}
