import 'dart:convert';
import 'dart:developer' as developer;

/// HTTP Logger for debugging API requests and responses
class HttpLogger {
  static const String _tag = 'HTTP';
  static bool enabled = true;

  /// Log HTTP request
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('╔══════════════════════════════════════════════════════════════');
    buffer.writeln('║ REQUEST');
    buffer.writeln('╠══════════════════════════════════════════════════════════════');
    buffer.writeln('║ $method $url');
    buffer.writeln('╠══════════════════════════════════════════════════════════════');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('║ Headers:');
      headers.forEach((key, value) {
        // Mask authorization token for security
        if (key.toLowerCase() == 'authorization') {
          final masked = value.length > 20
              ? '${value.substring(0, 15)}...${value.substring(value.length - 5)}'
              : '***';
          buffer.writeln('║   $key: $masked');
        } else {
          buffer.writeln('║   $key: $value');
        }
      });
    }

    if (body != null) {
      buffer.writeln('╠══════════════════════════════════════════════════════════════');
      buffer.writeln('║ Body:');
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          final prettyBody = _prettyJson(decoded);
          for (final line in prettyBody.split('\n')) {
            buffer.writeln('║   $line');
          }
        } else if (body is Map) {
          final prettyBody = _prettyJson(body);
          for (final line in prettyBody.split('\n')) {
            buffer.writeln('║   $line');
          }
        } else {
          buffer.writeln('║   $body');
        }
      } catch (_) {
        buffer.writeln('║   $body');
      }
    }

    buffer.writeln('╚══════════════════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: _tag);
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Log HTTP response
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    dynamic body,
    Duration? duration,
  }) {
    if (!enabled) return;

    final statusEmoji = _getStatusEmoji(statusCode);
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('╔══════════════════════════════════════════════════════════════');
    buffer.writeln('║ RESPONSE $statusEmoji');
    buffer.writeln('╠══════════════════════════════════════════════════════════════');
    buffer.writeln('║ $method $url');
    buffer.writeln('║ Status: $statusCode ${_getStatusText(statusCode)}');
    if (duration != null) {
      buffer.writeln('║ Duration: ${duration.inMilliseconds}ms');
    }
    buffer.writeln('╠══════════════════════════════════════════════════════════════');

    if (body != null) {
      buffer.writeln('║ Body:');
      try {
        dynamic decoded;
        if (body is String) {
          decoded = jsonDecode(body);
        } else {
          decoded = body;
        }
        final prettyBody = _prettyJson(decoded);
        for (final line in prettyBody.split('\n')) {
          buffer.writeln('║   $line');
        }
      } catch (_) {
        // Truncate long responses
        final bodyStr = body.toString();
        if (bodyStr.length > 500) {
          buffer.writeln('║   ${bodyStr.substring(0, 500)}...');
          buffer.writeln('║   [Truncated - ${bodyStr.length} chars total]');
        } else {
          buffer.writeln('║   $bodyStr');
        }
      }
    }

    buffer.writeln('╚══════════════════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: _tag);
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Log HTTP error
  static void logError({
    required String method,
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('╔══════════════════════════════════════════════════════════════');
    buffer.writeln('║ ERROR ❌');
    buffer.writeln('╠══════════════════════════════════════════════════════════════');
    buffer.writeln('║ $method $url');
    buffer.writeln('╠══════════════════════════════════════════════════════════════');
    buffer.writeln('║ Error: $error');
    if (stackTrace != null) {
      buffer.writeln('╠══════════════════════════════════════════════════════════════');
      buffer.writeln('║ StackTrace:');
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        buffer.writeln('║   $line');
      }
      if (stackTrace.toString().split('\n').length > 5) {
        buffer.writeln('║   ... (truncated)');
      }
    }
    buffer.writeln('╚══════════════════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: _tag);
    // ignore: avoid_print
    print(buffer.toString());
  }

  static String _prettyJson(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  static String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '↪️';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    return '❌';
  }

  static String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return '';
    }
  }
}
