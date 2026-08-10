import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/announcement_model.dart';
import '../models/responses/unread_count_model.dart';
import 'auth_local_datasource.dart';
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';

class AnnouncementRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  AnnouncementRemoteDatasource(this.client, this.authLocalDatasource);

  Future<List<AnnouncementModel>> getAnnouncements({int page = 1}) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/announcements?page=$page'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> announcementsData = data['data'];
      return announcementsData
          .map((json) => AnnouncementModel.fromJson(json))
          .toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  Future<AnnouncementModel> getAnnouncementDetail(int id) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/announcements/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return AnnouncementModel.fromJson(data['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load announcement detail');
    }
  }

  Future<void> markAsRead(int id) async {
    final token = await authLocalDatasource.getToken();
    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/announcements/$id/read'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to mark announcement as read');
    }
  }

  Future<UnreadCountModel> getUnreadCount() async {
    final token = await authLocalDatasource.getToken();
    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/announcements/unread-count'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UnreadCountModel.fromJson(data['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load unread count');
    }
  }
}
