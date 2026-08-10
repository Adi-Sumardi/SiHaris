import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasourceBase {}

class FakeUri extends Fake implements Uri {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  late LeaveRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockAuthLocalDatasource;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    datasource = LeaveRemoteDatasource(
      client: mockHttpClient,
      authLocalDatasource: mockAuthLocalDatasource,
    );
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  const tAuthToken = 'test_token';
  const tHeaders = {
    'Accept': 'application/json',
    'Authorization': 'Bearer $tAuthToken',
  };

  void setUpMockToken() {
    when(
      () => mockAuthLocalDatasource.getToken(),
    ).thenAnswer((_) async => tAuthToken);
  }

  group('getLeaveTypes', () {
    const tLeaveTypeModel = LeaveTypeModel(
      id: 1,
      name: 'Cuti Tahunan',
      quota: 12,
      isPaid: true,
      requiresAttachment: false,
    );

    test(
      'should return List<LeaveTypeModel> when response code is 200',
      () async {
        // arrange
        setUpMockToken();
        when(
          () => mockHttpClient.get(
            Uri.parse('${Variables.baseUrl}/leaves/types'),
            headers: tHeaders,
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"status": "success", "data": [{"id": 1, "name": "Cuti Tahunan", "quota": 12, "is_paid": true, "requires_attachment": false}]}',
            200,
          ),
        );

        // act
        final result = await datasource.getLeaveTypes();

        // assert
        expect(result, equals([tLeaveTypeModel]));
      },
    );
  });

  group('getLeaveBalances', () {
    const tLeaveBalanceModel = LeaveBalanceModel(
      leaveTypeId: 1,
      leaveTypeName: 'Cuti Tahunan',
      year: 2026,
      entitledDays: 12,
      usedDays: 2,
      pendingDays: 1,
      remainingDays: 9,
    );

    test('should return List<LeaveBalanceModel> when response code is 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/leaves/balance'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": [{"leave_type_id": 1, "leave_type_name": "Cuti Tahunan", "year": 2026, "entitled_days": 12, "used_days": 2, "pending_days": 1, "remaining_days": 9}]}',
          200,
        ),
      );

      // act
      final result = await datasource.getLeaveBalances();

      // assert
      expect(result, equals([tLeaveBalanceModel]));
    });
  });

  group('getLeaves', () {
    const tLeaveModel = LeaveModel(
      id: 1,
      requestNumber: 'LV-2024-001',
      leaveType: LeaveTypeModel(
        id: 1,
        name: 'Cuti Tahunan',
        quota: 12,
        isPaid: true,
        requiresAttachment: false,
      ),
      startDate: '2024-02-20',
      endDate: '2024-02-21',
      totalDays: 2,
      isHalfDay: false,
      status: 'pending',
      statusLabel: 'Menunggu Persetujuan',
      createdAt: '2024-02-01',
    );

    test('should return List<LeaveModel> when response code is 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/leaves?page=1'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": [{'
          '"id": 1,'
          '"request_number": "LV-2024-001",'
          '"leave_type": {"id": 1, "name": "Cuti Tahunan", "quota": 12, "is_paid": true, "requires_attachment": false},'
          '"start_date": "2024-02-20",'
          '"end_date": "2024-02-21",'
          '"total_days": 2,'
          '"is_half_day": false,'
          '"status": "pending",'
          '"status_label": "Menunggu Persetujuan",'
          '"created_at": "2024-02-01"'
          '}]}',
          200,
        ),
      );

      // act
      final result = await datasource.getLeaves();

      // assert
      expect(result, equals([tLeaveModel]));
    });
  });

  group('createLeaveRequest', () {
    final tLeaveRequest = LeaveRequestModel(
      leaveTypeId: 1,
      startDate: '2024-02-20',
      endDate: '2024-02-21',
      reason: 'Sakit',
      emergencyContact: '08123456789',
    );

    test(
      'should return true when creation is successful (200 or 201)',
      () async {
        // arrange
        setUpMockToken();
        when(() => mockHttpClient.send(any())).thenAnswer(
          (_) async => http.StreamedResponse(
            Stream.value(
              utf8.encode(
                '{"status": "success", "message": "Leave request created"}',
              ),
            ),
            201,
          ),
        );

        // act
        final result = await datasource.createLeaveRequest(tLeaveRequest);

        // assert
        expect(result, true);
      },
    );
  });

  group('cancelLeaveRequest', () {
    test('should return true when cancellation is successful (200)', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.post(
          Uri.parse('${Variables.baseUrl}/leaves/1/cancel'),
          headers: tHeaders,
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "message": "Leave request cancelled"}',
          200,
        ),
      );

      // act
      final result = await datasource.cancelLeaveRequest(1, 'Changed mind');

      // assert
      expect(result, true);
    });
  });
}
