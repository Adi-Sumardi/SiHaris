import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';
import '../utils/error_parser.dart';
import 'session_service.dart';
import 'storage_service.dart';

/// HTTP API service with interceptors for authentication and error handling
class ApiService {
  final http.Client client;
  final StorageService storageService;
  final String baseUrl;

  ApiService({
    required this.client,
    required this.storageService,
    required this.baseUrl,
  });

  /// Build headers with optional authentication token
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? customHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authorization header if token exists
    final token = await storageService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Merge custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Build URI with optional query parameters
  Uri _buildUri(String endpoint, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// Handle HTTP response and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : _parseResponseBody(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 204:
        return null;
      case 400:
        throw BadRequestException(
          message: _extractErrorMessage(body) ?? 'Permintaan tidak valid',
          data: body,
        );
      case 401:
        // Handle session expired - clear data and redirect to login
        SessionService.instance.handleSessionExpired();
        throw UnauthorizedException(
          message: _extractErrorMessage(body) ?? 'Sesi Anda telah berakhir',
          data: body,
        );
      case 403:
        throw ForbiddenException(
          message: _extractErrorMessage(body) ?? 'Akses ditolak',
          data: body,
        );
      case 404:
        throw NotFoundException(
          message: _extractErrorMessage(body) ?? 'Data tidak ditemukan',
          data: body,
        );
      case 422:
        throw ValidationException(
          message: _extractErrorMessage(body) ?? 'Validasi gagal',
          errors: _extractValidationErrors(body),
          data: body,
        );
      case 500:
      case 502:
      case 503:
      default:
        if (response.statusCode >= 500) {
          throw ServerException(
            message: _extractErrorMessage(body) ?? 'Terjadi kesalahan server',
            statusCode: response.statusCode,
            data: body,
          );
        }
        throw ServerException(
          message: _extractErrorMessage(body) ?? 'Terjadi kesalahan',
          statusCode: response.statusCode,
          data: body,
        );
    }
  }

  /// Parse response body as JSON
  dynamic _parseResponseBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  /// Extract error message from response body
  String? _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['message'] as String?;
    }
    return null;
  }

  /// Extract validation errors from response body
  Map<String, List<String>>? _extractValidationErrors(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('errors')) {
      final errors = body['errors'];
      if (errors is Map) {
        return errors.map((key, value) {
          if (value is List) {
            return MapEntry(
              key.toString(),
              value.map((e) => e.toString()).toList(),
            );
          }
          return MapEntry(key.toString(), [value.toString()]);
        });
      }
    }
    return null;
  }

  /// Perform GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await client.get(uri, headers: requestHeaders);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal terhubung ke server'),
      );
    }
  }

  /// Perform POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await client.post(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal terhubung ke server'),
      );
    }
  }

  /// Perform PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await client.put(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal terhubung ke server'),
      );
    }
  }

  /// Perform PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await client.patch(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal terhubung ke server'),
      );
    }
  }

  /// Perform DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await client.delete(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal terhubung ke server'),
      );
    }
  }

  /// Perform multipart POST request for file uploads
  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await storageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add custom headers
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: ErrorParser.parseException(e, fallback: 'Gagal mengunggah file'),
      );
    }
  }
}
