import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/approval_remote_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/core/constants/variables.dart';

class MockClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

void main() {
  late ApprovalRemoteDatasource datasource;
  late MockClient mockClient;
  late MockAuthLocalDatasource mockAuthLocal;

  setUp(() {
    mockClient = MockClient();
    mockAuthLocal = MockAuthLocalDatasource();
    datasource = ApprovalRemoteDatasource(mockClient, mockAuthLocal);

    registerFallbackValue(Uri());

    when(() => mockAuthLocal.getToken()).thenAnswer((_) async => 'test-token');
  });

  group('getPendingApprovals', () {
    test('should return PendingApprovalsModel on success', () async {
      when(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/pending'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('''
        {
          "data": {
            "leave_requests": [],
            "overtime_requests": [],
            "reimbursements": [],
            "total_pending": 0
          }
        }
      ''', 200),
      );

      final result = await datasource.getPendingApprovals();

      expect(result.totalPending, 0);
      verify(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/pending'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('should throw exception on error', () async {
      when(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/pending'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => datasource.getPendingApprovals(), throwsException);
    });
  });

  group('approveLeave', () {
    test('should complete successfully', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/leave/1/approve'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Approved"}', 200));

      await datasource.approveLeave(1, 'Approved');

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/leave/1/approve'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });

  group('rejectLeave', () {
    test('should complete successfully with notes', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/leave/1/reject'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Rejected"}', 200));

      await datasource.rejectLeave(1, 'Not enough quota');

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/leave/1/reject'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });

  group('approveReimbursement', () {
    test('should complete successfully', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/5/approve'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Approved"}', 200));

      await datasource.approveReimbursement(5, null);

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/5/approve'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });

  group('rejectReimbursement', () {
    test('should complete successfully with notes', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/5/reject'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Rejected"}', 200));

      await datasource.rejectReimbursement(5, 'Receipt not clear');

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.apiBaseUrl}/approvals/reimbursement/5/reject'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });

  group('getApprovalHistory', () {
    test('should return list of ApprovalHistoryModel on success', () async {
      when(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/history?page=1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('''
        {
          "data": [
            {
              "id": 1,
              "type": "leave",
              "employee_name": "John Doe",
              "status": "approved",
              "approved_at": "2026-02-15T10:00:00Z",
              "notes": null
            }
          ]
        }
      ''', 200),
      );

      final result = await datasource.getApprovalHistory(page: 1);

      expect(result.length, 1);
      expect(result[0].type, 'leave');
      expect(result[0].status, 'approved');
      verify(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/history?page=1'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('should throw exception on error', () async {
      when(
        () => mockClient.get(
          Uri.parse('${Variables.apiBaseUrl}/approvals/history?page=1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => datasource.getApprovalHistory(page: 1), throwsException);
    });
  });
}
