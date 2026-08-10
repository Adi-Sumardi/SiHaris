import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/variables.dart';
import '../../core/services/http_logger.dart';
import '../../core/services/session_service.dart';
import '../models/requests/register_request_model.dart';
import '../models/requests/update_profile_request_model.dart';
import '../models/responses/auth_response_model.dart';
import '../models/responses/register_response_model.dart';
import 'auth_datasource.dart';
import 'auth_local_datasource.dart';

class AuthRemoteDatasource implements AuthDatasource {
  final http.Client _client;
  final AuthLocalDatasourceBase _localDatasource;

  AuthRemoteDatasource({
    http.Client? client,
    AuthLocalDatasourceBase? localDatasource,
  })  : _client = client ?? http.Client(),
        _localDatasource = localDatasource ?? AuthLocalDatasource();

  @override
  Future<Either<String, AuthResponseModel>> login(
    String identifier,
    String password,
  ) async {
    final url = Variables.login;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = {
      'employee_id': identifier,
      'password': password,
    };

    HttpLogger.logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(AuthResponseModel.fromJson(data));
      } else {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Login gagal');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(
        method: 'POST',
        url: url,
        error: e,
        stackTrace: stackTrace,
      );
      return Left('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<Either<String, RegisterResponseModel>> demoRegister(
    RegisterRequestModel request,
  ) async {
    final url = Variables.demoRegister;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = request.toJson();

    HttpLogger.logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Right(RegisterResponseModel.fromJson(data));
      } else {
        return Left(data['message'] ?? 'Registrasi gagal');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(
        method: 'POST',
        url: url,
        error: e,
        stackTrace: stackTrace,
      );
      return Left('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<Either<String, bool>> logout() async {
    final url = Variables.logout;
    final token = await _localDatasource.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    HttpLogger.logRequest(method: 'POST', url: url, headers: headers);

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      // FORCE LOGOUT: Always clear local data regardless of API response
      await _localDatasource.removeAuthData();
      return const Right(true);
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(method: 'POST', url: url, error: e, stackTrace: stackTrace);

      // FORCE LOGOUT: Even on error, clear local data and return success
      await _localDatasource.removeAuthData();
      return const Right(true);
    }
  }

  @override
  Future<Either<String, (UserModel, CompanyModel?)>> getProfile() async {
    final url = Variables.profile;
    final token = await _localDatasource.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    HttpLogger.logRequest(method: 'GET', url: url, headers: headers);

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['data']);
        final companyData = data['data']['company'];
        final company = companyData != null
            ? CompanyModel.fromJson(companyData)
            : null;
        return Right((user, company));
      } else if (response.statusCode == 401) {
        // Handle session expired
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Gagal mengambil profile');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(method: 'GET', url: url, error: e, stackTrace: stackTrace);
      return Left('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<Either<String, UserModel>> updateProfile(
      UpdateProfileRequestModel request) async {
    final url = Variables.profile;
    final token = await _localDatasource.getToken();

    final multipartRequest = http.MultipartRequest('PATCH', Uri.parse(url));
    multipartRequest.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    multipartRequest.fields.addAll(request.toFields());

    // Add photo file if present
    if (request.hasPhoto) {
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('photo', request.photo!.path),
      );
    }

    HttpLogger.logRequest(
      method: 'PATCH',
      url: url,
      headers: multipartRequest.headers,
      body: request.toFields(),
    );

    final stopwatch = Stopwatch()..start();

    try {
      final streamedResponse = await _client.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'PATCH',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(UserModel.fromJson(data['data']));
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(
          method: 'PATCH', url: url, error: e, stackTrace: stackTrace);
      return Left('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<Either<String, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Variables.changePassword;
    final token = await _localDatasource.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    };

    HttpLogger.logRequest(method: 'POST', url: url, headers: headers, body: body);

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Gagal mengubah password');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(method: 'POST', url: url, error: e, stackTrace: stackTrace);
      return Left('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<Either<String, bool>> deleteAccount({
    required String password,
    required String confirmation,
    String? reason,
  }) async {
    final url = Variables.deleteAccount;
    final token = await _localDatasource.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = <String, dynamic>{
      'password': password,
      'confirmation': confirmation,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    HttpLogger.logRequest(method: 'DELETE', url: url, headers: headers, body: body);

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'DELETE',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        // Clear local auth data after successful deletion
        await _localDatasource.removeAuthData();
        return const Right(true);
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Password tidak sesuai');
      } else {
        final data = jsonDecode(response.body);
        return Left(data['message'] ?? 'Gagal menghapus akun');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      HttpLogger.logError(method: 'DELETE', url: url, error: e, stackTrace: stackTrace);
      return Left('Terjadi kesalahan: $e');
    }
  }
}
