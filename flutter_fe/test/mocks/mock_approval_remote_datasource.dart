import 'package:gaji_pro/data/datasources/approval_remote_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/responses/approval_history_model.dart';
import 'package:gaji_pro/data/models/responses/pending_approvals_model.dart';
import 'package:http/http.dart' as http;

/// Mock implementation of ApprovalRemoteDatasource for testing
class MockApprovalRemoteDatasource implements ApprovalRemoteDatasource {
  bool shouldFail = false;

  @override
  http.Client get client => throw UnimplementedError();

  @override
  AuthLocalDatasource get authLocalDatasource => throw UnimplementedError();

  @override
  Future<PendingApprovalsModel> getPendingApprovals() async {
    if (shouldFail) throw Exception('Failed to load pending approvals');
    return const PendingApprovalsModel(
      leaveRequests: [],
      overtimeRequests: [],
      reimbursements: [],
      totalPending: 0,
    );
  }

  @override
  Future<void> approveLeave(int id, String? notes) async {
    if (shouldFail) throw Exception('Failed to approve leave');
    return;
  }

  @override
  Future<void> rejectLeave(int id, String notes) async {
    if (shouldFail) throw Exception('Failed to reject leave');
    return;
  }

  @override
  Future<void> approveOvertime(int id, String? notes) async {
    if (shouldFail) throw Exception('Failed to approve overtime');
    return;
  }

  @override
  Future<void> rejectOvertime(int id, String notes) async {
    if (shouldFail) throw Exception('Failed to reject overtime');
    return;
  }

  @override
  Future<void> approveReimbursement(int id, String? notes) async {
    if (shouldFail) throw Exception('Failed to approve reimbursement');
    return;
  }

  @override
  Future<void> rejectReimbursement(int id, String notes) async {
    if (shouldFail) throw Exception('Failed to reject reimbursement');
    return;
  }

  @override
  Future<List<ApprovalHistoryModel>> getApprovalHistory({int page = 1}) async {
    if (shouldFail) throw Exception('Failed to load approval history');
    return [
      const ApprovalHistoryModel(
        type: 'leave',
        id: 1,
        employeeName: 'John Doe',
        status: 'approved',
        approvedAt: '2026-02-15T10:00:00Z',
      ),
    ];
  }
}
