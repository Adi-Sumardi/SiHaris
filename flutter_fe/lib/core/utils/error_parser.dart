import 'dart:convert';
import 'dart:io';
import '../errors/exceptions.dart';

class ErrorParser {
  /// Check if the error or message represents a network/offline error
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    if (error is SocketException || error is NetworkException) {
      return true;
    }
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('failed host lookup') ||
        str.contains('no address associated with hostname') ||
        str.contains('network is unreachable') ||
        str.contains('network error') ||
        str.contains('no internet') ||
        str.contains('internet connection') ||
        str.contains('connection refused') ||
        str.contains('connection reset') ||
        str.contains('connection closed') ||
        str.contains('connection abort') ||
        str.contains('broken pipe') ||
        str.contains('software caused connection abort') ||
        str.contains('errno = 7') ||
        str.contains('errno = 101') ||
        str.contains('errno = 111') ||
        str.contains('os error:');
  }

  /// Check if the error represents a timeout
  static bool isTimeoutError(dynamic error) {
    if (error == null) return false;
    if (error is TimeoutException) return true;
    final str = error.toString().toLowerCase();
    return str.contains('timeoutexception') ||
        str.contains('timeout') ||
        str.contains('timed out') ||
        str.contains('deadline exceeded');
  }

  /// Check if a raw string contains technical exception syntax or stack traces
  static bool isTechnicalError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('clientexception') ||
        lower.contains('socketexception') ||
        lower.contains('typeerror') ||
        lower.contains('formatexception') ||
        lower.contains('null is not a subtype') ||
        lower.contains('stacktrace') ||
        lower.contains('errno =') ||
        lower.contains('os error:') ||
        lower.contains('uri=http') ||
        lower.contains('sqlstate');
  }

  /// Sanitize technical error string to a friendly Indonesian message
  static String sanitizeTechnicalError(
    String message, {
    String fallback = 'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.',
  }) {
    if (isNetworkError(message)) {
      return 'Terjadi kesalahan koneksi: Tidak ada koneksi internet. Silakan periksa jaringan Wi-Fi atau data seluler Anda.';
    }
    if (isTimeoutError(message)) {
      return 'Koneksi ke server terputus (timeout). Silakan coba lagi beberapa saat.';
    }
    if (isTechnicalError(message)) {
      return fallback;
    }
    var cleaned = message.trim();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring(11).trim();
    }
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  /// Parse any Dart Exception or technical Error object into a user-friendly Indonesian message
  static String parseException(
    dynamic error, {
    String fallback = 'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.',
  }) {
    if (error == null) return fallback;

    // 1. Network / Offline errors
    if (isNetworkError(error)) {
      return 'Terjadi kesalahan koneksi: Tidak ada koneksi internet. Silakan periksa jaringan Wi-Fi atau data seluler Anda.';
    }

    // 2. Timeout errors
    if (isTimeoutError(error)) {
      return 'Koneksi ke server terputus (timeout). Silakan coba lagi beberapa saat.';
    }

    // 3. ServerException
    if (error is ServerException) {
      return 'Terjadi kendala pada server (Kode: ${error.statusCode ?? 500}). Silakan coba beberapa saat lagi.';
    }

    // 4. Other AppExceptions
    if (error is AppException) {
      return error.message;
    }

    // 5. Decoding / Type parsing errors
    if (error is TypeError || error is FormatException) {
      return 'Format respon server tidak sesuai. Silakan coba lagi.';
    }

    // 6. Generic string cleanup
    final str = error.toString();
    if (isTechnicalError(str)) {
      return fallback;
    }

    var cleaned = str;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring(11).trim();
    }

    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  /// Parse response body (from HTTP response) into clean string
  static String parse(
    dynamic body, {
    String fallback = 'Terjadi kesalahan',
  }) {
    if (body == null) return fallback;

    // 1. String payload
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        return parse(decoded, fallback: fallback);
      } catch (_) {
        return sanitizeTechnicalError(body, fallback: fallback);
      }
    }

    // 2. Map payload (Laravel format: {message: ..., errors: ...})
    if (body is Map) {
      // Prioritize message if present and meaningful
      if (body['message'] is String &&
          (body['message'] as String).trim().isNotEmpty) {
        return sanitizeTechnicalError(body['message'] as String, fallback: fallback);
      }

      // Check errors map
      if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
        final errors = body['errors'] as Map;
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return sanitizeTechnicalError(firstValue.first.toString(), fallback: fallback);
        }
        if (firstValue is String && firstValue.isNotEmpty) {
          return sanitizeTechnicalError(firstValue, fallback: fallback);
        }
      }

      if (body['error'] is String && (body['error'] as String).trim().isNotEmpty) {
        return sanitizeTechnicalError(body['error'] as String, fallback: fallback);
      }
    }

    return fallback;
  }
}
