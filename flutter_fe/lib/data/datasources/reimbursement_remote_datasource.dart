import 'dart:convert';
import 'dart:io';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/requests/reimbursement_request_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_summary_model.dart';
import 'package:http/http.dart' as http;

class ReimbursementRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  ReimbursementRemoteDatasource(this.client, this.authLocalDatasource);

  Future<List<ReimbursementModel>> getReimbursements({
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final token = await authLocalDatasource.getToken();
    final queryParams = <String, String>{'page': page.toString()};

    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse(
      Variables.reimbursements,
    ).replace(queryParameters: queryParams);

    final response = await client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] as List;
      return data.map((json) => ReimbursementModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load reimbursements');
    }
  }

  Future<ReimbursementModel> createReimbursement(
    ReimbursementRequestModel request,
    File? receiptFile,
  ) async {
    final token = await authLocalDatasource.getToken();
    final uri = Uri.parse(Variables.reimbursements);

    final multipartRequest = http.MultipartRequest('POST', uri);
    multipartRequest.headers['Authorization'] = 'Bearer $token';

    request.addToMultipartRequest(multipartRequest, receiptFile);

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ReimbursementModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to create reimbursement');
    }
  }

  Future<ReimbursementModel> getReimbursementDetail(int id) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse(Variables.reimbursementDetail(id)),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ReimbursementModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load reimbursement detail');
    }
  }

  Future<List<ReimbursementCategoryModel>> getCategories() async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse(Variables.reimbursementCategories),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] as List;
      return data
          .map((json) => ReimbursementCategoryModel.fromJson(json))
          .toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<ReimbursementSummaryModel> getSummary({
    required int month,
    required int year,
  }) async {
    final token = await authLocalDatasource.getToken();
    final uri = Uri.parse(Variables.reimbursementSummary).replace(
      queryParameters: {'month': month.toString(), 'year': year.toString()},
    );

    final response = await client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ReimbursementSummaryModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load summary');
    }
  }
}
