import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/models/responses/tax_form_model.dart';
import 'package:gaji_pro/data/models/responses/tax_form_detail_model.dart';

class TaxFormRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasourceBase authLocalDatasource;

  static const _tag = 'TaxFormDatasource';

  TaxFormRemoteDatasource({
    required this.client,
    required this.authLocalDatasource,
  });

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  /// Get list of tax forms (bukti potong 1721-A1)
  Future<List<TaxFormModel>> getTaxForms({int? year}) async {
    String url = Variables.taxForms;
    if (year != null) {
      url += '?year=$year';
    }
    _log('GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      _log('Token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        _log('Parsing ${data.length} tax forms');
        return data.map((json) => TaxFormModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _log('401 Unauthorized - session expired');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Unknown error';
        _log('Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('Exception: $e');
      _log('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get available tax years
  Future<List<TaxFormYearModel>> getTaxFormYears() async {
    final url = Variables.taxFormYears;
    _log('GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        _log('Parsing ${data.length} tax years');
        return data.map((json) => TaxFormYearModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _log('401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to load tax years';
        _log('Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('Exception: $e');
      _log('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get tax form detail
  Future<TaxFormDetailModel> getTaxFormDetail(int id) async {
    final url = Variables.taxFormDetail(id);
    _log('GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('Response [${response.statusCode}]: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _log('Parsing tax form detail');
        return TaxFormDetailModel.fromJson(data);
      } else if (response.statusCode == 401) {
        _log('401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else if (response.statusCode == 404) {
        throw Exception('Bukti potong tidak ditemukan');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to load tax form detail';
        _log('Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('Exception: $e');
      _log('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get download URL for tax form PDF
  Future<TaxFormDownloadModel> downloadTaxForm(int id) async {
    final url = Variables.taxFormDownload(id);
    _log('GET $url');

    try {
      final token = await authLocalDatasource.getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _log('Parsing download response');
        return TaxFormDownloadModel.fromJson(data);
      } else if (response.statusCode == 401) {
        _log('401 Unauthorized');
        SessionService.instance.handleSessionExpired();
        throw Exception('Sesi Anda telah berakhir');
      } else if (response.statusCode == 404) {
        throw Exception('Bukti potong tidak ditemukan');
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to download tax form';
        _log('Error ${response.statusCode}: $message');
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      _log('Exception: $e');
      _log('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
