import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/overtime_model.dart';
import '../models/responses/overtime_summary_model.dart';
import '../models/requests/overtime_request_model.dart';
import 'auth_local_datasource.dart';
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';

class OvertimeRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  OvertimeRemoteDatasource(this.client, this.authLocalDatasource);

  Future<List<OvertimeModel>> getOvertimes({
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final token = await authLocalDatasource.getToken();
    final queryParams = {
      'page': page.toString(),
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '${Variables.apiBaseUrl}/overtimes',
    ).replace(queryParameters: queryParams);

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data'];
      return data.map((e) => OvertimeModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load overtimes');
    }
  }

  Future<void> createOvertime(OvertimeRequestModel request) async {
    final token = await authLocalDatasource.getToken();

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/overtimes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 201) {
      throw Exception('Failed to create overtime request');
    }
  }

  Future<void> cancelOvertime(int id) async {
    final token = await authLocalDatasource.getToken();

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/overtimes/$id/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to cancel overtime request');
    }
  }

  Future<OvertimeSummaryModel> getOvertimeSummary({
    required int month,
    required int year,
  }) async {
    final token = await authLocalDatasource.getToken();
    final queryParams = {'month': month.toString(), 'year': year.toString()};

    final uri = Uri.parse(
      '${Variables.apiBaseUrl}/overtimes/summary',
    ).replace(queryParameters: queryParams);

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return OvertimeSummaryModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load overtime summary');
    }
  }
}
