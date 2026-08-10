import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_detail_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_download_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_summary_model.dart';

class PayslipRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasourceBase authLocalDatasource;

  static const _tag = 'PayslipDatasource';

  PayslipRemoteDatasource({
    required this.client,
    required this.authLocalDatasource,
  });

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<List<PayslipModel>> getPayslips({
    required int year,
    int page = 1,
  }) async {
    final url = '${Variables.payslips}?year=$year&page=$page';
    _log('📤 GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      _log('🔑 Token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');

      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      _log('📥 Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _log('📦 Parsed body keys: ${body.keys.toList()}');

        final dataField = body['data'];
        if (dataField == null) {
          _log('❌ body["data"] is null');
          throw Exception('Response data is null');
        }
        _log('📦 data field type: ${dataField.runtimeType}');

        // Handle both paginated and non-paginated responses
        List<dynamic> items;
        if (dataField is List) {
          items = dataField;
        } else if (dataField is Map && dataField['data'] != null) {
          items = dataField['data'] as List<dynamic>;
        } else {
          _log('❌ Unexpected data structure: $dataField');
          throw Exception('Unexpected data structure');
        }

        _log('✅ Parsing ${items.length} payslips');
        return items.map((json) => PayslipModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _log('🚫 401 Unauthorized - session expired');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Unknown error';
        _log('❌ Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('💥 Exception: $e');
      _log('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<PayslipDetailModel> getPayslipDetail(int id) async {
    final url = Variables.payslipDetail(id);
    _log('📤 GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      _log('📥 Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _log('✅ Parsing payslip detail');
        return PayslipDetailModel.fromJson(data);
      } else if (response.statusCode == 401) {
        _log('🚫 401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to load payslip detail';
        _log('❌ Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('💥 Exception: $e');
      _log('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<PayslipDownloadModel> downloadPayslip(int id) async {
    final url = Variables.payslipDownload(id);
    _log('📤 GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      _log('📥 Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _log('✅ Parsing download response');
        return PayslipDownloadModel.fromJson(data);
      } else if (response.statusCode == 401) {
        _log('🚫 401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to download payslip';
        _log('❌ Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('💥 Exception: $e');
      _log('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<PayslipSummaryModel> getPayslipSummary({required int year}) async {
    final url = '${Variables.payslipSummary}?year=$year';
    _log('📤 GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      _log('📥 Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _log('✅ Parsing payslip summary');
        return PayslipSummaryModel.fromJson(data);
      } else if (response.statusCode == 401) {
        _log('🚫 401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to load payslip summary';
        _log('❌ Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('💥 Exception: $e');
      _log('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }
}
