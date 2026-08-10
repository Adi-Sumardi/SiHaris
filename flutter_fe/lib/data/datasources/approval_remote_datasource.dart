import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/pending_approvals_model.dart';
import '../models/responses/approval_history_model.dart';
import '../models/requests/approval_action_request.dart';
import 'auth_local_datasource.dart';
import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';

class ApprovalRemoteDatasource {
  final http.Client client;
  final AuthLocalDatasource authLocalDatasource;

  ApprovalRemoteDatasource(this.client, this.authLocalDatasource);

  Future<PendingApprovalsModel> getPendingApprovals() async {
    final token = await authLocalDatasource.getToken();

    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/approvals/pending'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return PendingApprovalsModel.fromJson(jsonData['data']);
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load pending approvals');
    }
  }

  Future<void> approveLeave(int id, String? notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/leave/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to approve leave');
    }
  }

  Future<void> rejectLeave(int id, String notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/leave/$id/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to reject leave');
    }
  }

  Future<void> approveOvertime(int id, String? notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/overtime/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to approve overtime');
    }
  }

  Future<void> rejectOvertime(int id, String notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/overtime/$id/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to reject overtime');
    }
  }

  Future<void> approveReimbursement(int id, String? notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to approve reimbursement');
    }
  }

  Future<void> rejectReimbursement(int id, String notes) async {
    final token = await authLocalDatasource.getToken();

    final request = ApprovalActionRequest(notes: notes);

    final response = await client.post(
      Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/$id/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to reject reimbursement');
    }
  }

  Future<List<ApprovalHistoryModel>> getApprovalHistory({int page = 1}) async {
    final token = await authLocalDatasource.getToken();

    final response = await client.get(
      Uri.parse('${Variables.apiBaseUrl}/approvals/history?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data'];
      return data.map((e) => ApprovalHistoryModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      SessionService.instance.handleSessionExpired();
      throw Exception('Sesi Anda telah berakhir');
    } else {
      throw Exception('Failed to load approval history');
    }
  }
}
