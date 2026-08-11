import 'dart:convert';

/// Helper utility to safely extract human-readable error messages from Backend JSON responses
/// without throwing TypeError exceptions on dynamic JSON structures.
class ErrorParser {
  static String parse(dynamic body, {String fallback = 'Terjadi kesalahan'}) {
    try {
      Map<String, dynamic> json;
      if (body is String) {
        json = jsonDecode(body) as Map<String, dynamic>;
      } else if (body is Map<String, dynamic>) {
        json = body;
      } else {
        return fallback;
      }

      // 1. Check "errors" field (Laravel validation format)
      if (json.containsKey('errors') && json['errors'] != null) {
        final errors = json['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          } else if (firstVal != null) {
            return firstVal.toString();
          }
        } else if (errors is String && errors.isNotEmpty) {
          return errors;
        }
      }

      // 2. Check top-level "message" field
      if (json.containsKey('message') && json['message'] != null) {
        final msg = json['message'].toString();
        if (msg.isNotEmpty && msg != 'The given data was invalid.') {
          return msg;
        }
      }

      // 3. Check top-level "error" field
      if (json.containsKey('error') && json['error'] != null) {
        final err = json['error'].toString();
        if (err.isNotEmpty) return err;
      }

      // 4. Fallback to message if no specific field error found
      if (json.containsKey('message') && json['message'] != null) {
        return json['message'].toString();
      }
    } catch (_) {
      // Return fallback on any json parsing failure
    }

    return fallback;
  }
}
