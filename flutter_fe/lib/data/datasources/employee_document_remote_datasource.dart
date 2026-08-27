import 'dart:convert';
import 'dart:io';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/requests/upload_document_request_model.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';
import 'package:http/http.dart' as http;

class EmployeeDocumentRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  EmployeeDocumentRemoteDatasource(this.client, this.authLocalDatasource);

  /// Mengambil daftar berkas/dokumen milik karyawan
  Future<List<EmployeeDocumentModel>> getDocuments({
    String? type,
    String? search,
  }) async {
    final token = await authLocalDatasource.getToken();
    final queryParams = <String, String>{};

    if (type != null && type.isNotEmpty && type != 'all') {
      queryParams['type'] = type;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse(Variables.documents).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] as List;
      return data.map((item) => EmployeeDocumentModel.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      final jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Gagal memuat daftar berkas');
    }
  }

  /// Mengambil daftar referensi jenis dokumen yang didukung
  Future<List<DocumentTypeModel>> getDocumentTypes() async {
    final token = await authLocalDatasource.getToken();
    final uri = Uri.parse(Variables.documentTypes);

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] as List;
      return data.map((item) => DocumentTypeModel.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Gagal memuat jenis dokumen');
    }
  }

  /// Mengunggah file berkas baru ke server
  Future<EmployeeDocumentModel> uploadDocument(
    UploadDocumentRequestModel request,
    File file,
  ) async {
    final token = await authLocalDatasource.getToken();
    final uri = Uri.parse(Variables.documents);

    final multipartRequest = http.MultipartRequest('POST', uri);
    multipartRequest.headers['Authorization'] = 'Bearer $token';
    multipartRequest.headers['Accept'] = 'application/json';

    request.addToMultipartRequest(multipartRequest, file);

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EmployeeDocumentModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode == 422) {
      final jsonData = json.decode(response.body);
      final errors = jsonData['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
      throw Exception(jsonData['message'] ?? 'Validasi dokumen gagal');
    } else {
      final jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Gagal mengunggah berkas');
    }
  }

  /// Mengambil detail satu berkas
  Future<EmployeeDocumentModel> getDocumentDetail(int id) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse(Variables.documentDetail(id)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EmployeeDocumentModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Berkas tidak ditemukan');
    }
  }

  /// Menghapus berkas
  Future<bool> deleteDocument(int id) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.delete(
      Uri.parse(Variables.documentDelete(id)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      final jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Gagal menghapus berkas');
    }
  }
}
