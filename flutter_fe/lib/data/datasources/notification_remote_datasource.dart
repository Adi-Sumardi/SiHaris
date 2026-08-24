import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/notification_model.dart';
import '../models/responses/unread_count_model.dart';
import 'auth_local_datasource.dart';
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';

class NotificationRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  NotificationRemoteDatasource(this.client, this.authLocalDatasource);

  Future<Map<String, String>> _headers() async {
    final token = await authLocalDatasource.getToken();
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    final response = await client.get(
      Uri.parse('${Variables.notifications}?page=$page'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> notificationsData = data['data'];
      return notificationsData
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markAsRead(int id) async {
    final response = await client.post(
      Uri.parse(Variables.notificationRead(id)),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    final response = await client.post(
      Uri.parse(Variables.notificationMarkAllRead),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  Future<void> deleteNotification(int id) async {
    final response = await client.delete(
      Uri.parse(Variables.notificationDelete(id)),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }

  Future<UnreadCountModel> getUnreadCount() async {
    final response = await client.get(
      Uri.parse(Variables.notificationUnreadCount),
      headers: await _headers(),
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
