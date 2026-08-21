import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/requests/validate_gps_request_model.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';

class OfficeLocationRemoteDatasource {
  final http.Client _client;
  final AuthLocalDatasourceBase _localDatasource;

  OfficeLocationRemoteDatasource({
    http.Client? client,
    AuthLocalDatasourceBase? localDatasource,
  })  : _client = client ?? http.Client(),
        _localDatasource = localDatasource ?? AuthLocalDatasource();

  Map<String, String> _getHeaders(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Either<String, List<OfficeLocationModel>>> getOfficeLocations() async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final response = await _client.get(
        Uri.parse(Variables.officeLocations),
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as List<dynamic>? ?? [];
        final offices = data
            .map((e) => OfficeLocationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(offices);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      }
      return Left(body['message'] ?? 'Terjadi kesalahan');
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<Either<String, List<OfficeLocationModel>>> getAssignedOffices() async {
    // 1. Try to fetch the latest assigned offices from API first
    try {
      final token = await _localDatasource.getToken();
      if (token != null) {
        final response = await _client.get(
          Uri.parse(Variables.officeLocationsAssigned),
          headers: _getHeaders(token),
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final data = body['data'] as List<dynamic>? ?? [];
          final offices = data
              .map((e) => OfficeLocationModel.fromJson(e as Map<String, dynamic>))
              .toList();

          if (offices.isNotEmpty) {
            await _localDatasource.saveAssignedOffices(offices);
          }
          return Right(offices);
        } else if (response.statusCode == 401) {
          SessionService.instance.handleSessionExpired();
          return const Left('Sesi Anda telah berakhir');
        }
      }
    } catch (_) {
      // Network error / offline, will fallback to local storage below
    }

    // 2. Fallback to local storage (saved during login/previous fetch)
    final localOffices = await _localDatasource.getAssignedOffices();
    if (localOffices.isNotEmpty) {
      return Right(localOffices);
    }

    return const Left('Lokasi kantor tidak ditemukan');
  }

  Future<Either<String, OfficeLocationModel>> getOfficeLocationDetail(
      int id) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final response = await _client.get(
        Uri.parse(Variables.officeLocationDetail(id)),
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) return Right(OfficeLocationModel.fromJson(data));
        return const Left('Data tidak ditemukan');
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      }
      return Left(body['message'] ?? 'Terjadi kesalahan');
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<Either<String, GpsValidationResponse>> validateGps(
      ValidateGpsRequestModel request) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final response = await _client.post(
        Uri.parse(Variables.officeLocationsValidateGps),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) return Right(GpsValidationResponse.fromJson(data));
        return const Left('Data tidak ditemukan');
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      }
      return Left(body['message'] ?? 'Terjadi kesalahan');
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }
}
