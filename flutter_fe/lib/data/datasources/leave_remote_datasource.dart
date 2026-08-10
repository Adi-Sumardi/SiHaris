import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';

class LeaveRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasourceBase authLocalDatasource;

  LeaveRemoteDatasource({
    required this.client,
    required this.authLocalDatasource,
  });

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/leaves/types'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => LeaveTypeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load leave types');
    }
  }

  Future<List<LeaveBalanceModel>> getLeaveBalances() async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/leaves/balance'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => LeaveBalanceModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load leave balances');
    }
  }

  Future<List<LeaveModel>> getLeaves({int page = 1}) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/leaves?page=$page'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => LeaveModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load leaves');
    }
  }

  Future<bool> createLeaveRequest(LeaveRequestModel request) async {
    final token = await authLocalDatasource.getToken();
    var requestMultipart = http.MultipartRequest(
      'POST',
      Uri.parse('${Variables.apiBaseUrl}/leaves'),
    );

    requestMultipart.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    requestMultipart.fields.addAll(request.toJson());

    if (request.attachment != null) {
      requestMultipart.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          request.attachment!.path,
        ),
      );
    }

    final response = await client.send(requestMultipart);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to create leave request: $respStr');
    }
  }

  Future<bool> cancelLeaveRequest(int id, String? reason) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/leaves/$id/cancel'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: reason != null ? {'reason': reason} : null,
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to cancel leave request: ${response.statusCode}');
    }
  }
}
