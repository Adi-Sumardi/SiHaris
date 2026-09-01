import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/error_parser.dart';
import '../models/responses/dashboard/dashboard_models.dart';
import 'auth_datasource.dart';
import 'auth_local_datasource.dart';
import 'dashboard_datasource.dart';

class DashboardRemoteDatasource implements DashboardDatasource {
  final http.Client _client;
  final AuthLocalDatasourceBase _localDatasource;

  DashboardRemoteDatasource({
    http.Client? client,
    AuthLocalDatasourceBase? localDatasource,
  })  : _client = client ?? http.Client(),
        _localDatasource = localDatasource ?? AuthLocalDatasource();

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<Either<String, DashboardResponseModel>> getDashboard() async {
    try {
      final token = await _localDatasource.getToken();

      if (token == null) {
        return const Left('Anda belum login');
      }

      final response = await _client.get(
        Uri.parse(Variables.dashboard),
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        try {
          return Right(DashboardResponseModel.fromJson(body));
        } catch (parseError) {
          debugPrint('Dashboard parse error: $parseError');
          debugPrint('Dashboard response body: $body');
          return Left(ErrorParser.parseException(parseError));
        }
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final message = ErrorParser.parse(body, fallback: 'Gagal memuat data dashboard');
        return Left(message);
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      return Left(ErrorParser.parseException(e));
    }
  }

  @override
  Future<Either<String, QuickStatsModel>> getQuickStats() async {
    try {
      final token = await _localDatasource.getToken();

      if (token == null) {
        return const Left('Anda belum login');
      }

      final response = await _client.get(
        Uri.parse(Variables.dashboardQuickStats),
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          try {
            return Right(QuickStatsModel.fromJson(data));
          } catch (parseError) {
            debugPrint('QuickStats parse error: $parseError');
            debugPrint('QuickStats response data: $data');
            return Left(ErrorParser.parseException(parseError));
          }
        }
        return const Left('Data tidak ditemukan');
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final message = ErrorParser.parse(body, fallback: 'Gagal memuat ringkasan');
        return Left(message);
      }
    } catch (e) {
      debugPrint('QuickStats error: $e');
      return Left(ErrorParser.parseException(e));
    }
  }

  @override
  Future<Either<String, AttendanceChartModel>> getAttendanceChart({
    int days = 7,
  }) async {
    try {
      final token = await _localDatasource.getToken();

      if (token == null) {
        return const Left('Anda belum login');
      }

      final uri = Uri.parse(Variables.dashboardAttendanceChart).replace(
        queryParameters: {'days': days.toString()},
      );

      final response = await _client.get(
        uri,
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Right(AttendanceChartModel.fromJson(data));
        }
        return const Left('Data tidak ditemukan');
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final message = ErrorParser.parse(body, fallback: 'Gagal memuat grafik kehadiran');
        return Left(message);
      }
    } catch (e) {
      return Left(ErrorParser.parseException(e));
    }
  }
}
