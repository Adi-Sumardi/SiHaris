import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import 'auth_local_datasource.dart';
import '../models/requests/register_token_request_model.dart';
import '../models/responses/device_token_model.dart';

class DeviceTokenRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  DeviceTokenRemoteDatasource(this.client, this.authLocalDatasource);

  Future<void> registerToken(RegisterTokenRequestModel request) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.post(
      Uri.parse(Variables.deviceTokenRegister),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register device token');
    }
  }

  Future<void> unregisterToken(String token) async {
    final authToken = await authLocalDatasource.getToken();
    final response = await client.delete(
      Uri.parse(Variables.deviceTokenUnregister),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to unregister device token');
    }
  }

  Future<List<DeviceTokenModel>> getDeviceTokens() async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/device-tokens'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => DeviceTokenModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load device tokens');
    }
  }

  Future<void> refreshToken(String oldToken, String newToken) async {
    final authToken = await authLocalDatasource.getToken();
    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/device-tokens/refresh'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_token': oldToken,
        'new_token': newToken,
      }),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to refresh device token');
    }
  }
}
