import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/responses/employee_schedule_model.dart';

class ScheduleRemoteDatasource {
  final http.Client _client;
  final AuthLocalDatasourceBase _localDatasource;

  ScheduleRemoteDatasource({
    http.Client? client,
    AuthLocalDatasourceBase? localDatasource,
  }) : _client = client ?? http.Client(),
       _localDatasource = localDatasource ?? AuthLocalDatasource();

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch the resolved monthly schedule for the authenticated employee.
  /// [month] must be in `YYYY-MM` format. When null, the backend uses the current month.
  Future<Either<String, EmployeeScheduleResponse>> getMonthlySchedule({
    String? month,
  }) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final uri = Uri.parse(Variables.schedule).replace(
        queryParameters: month != null ? {'month': month} : null,
      );

      final response = await _client.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Right(EmployeeScheduleResponse.fromJson(data));
        }
        return const Left('Data jadwal tidak ditemukan');
      }

      return Left((body['message'] as String?) ?? 'Gagal memuat jadwal');
    } catch (e) {
      return Left('Terjadi kesalahan: $e');
    }
  }
}
