import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/overtime_remote_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/models/requests/overtime_request_model.dart';
import 'package:gaji_pro/data/models/responses/overtime_model.dart';
import 'package:gaji_pro/data/models/responses/overtime_summary_model.dart';

class MockClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

void main() {
  late OvertimeRemoteDatasource datasource;
  late MockClient mockClient;
  late MockAuthLocalDatasource mockAuthLocal;

  setUp(() {
    mockClient = MockClient();
    mockAuthLocal = MockAuthLocalDatasource();
    datasource = OvertimeRemoteDatasource(mockClient, mockAuthLocal);

    registerFallbackValue(Uri());
    when(() => mockAuthLocal.getToken()).thenAnswer((_) async => 'test-token');
  });

  group('getOvertimes', () {
    test('should return List<OvertimeModel> on success', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('''
        {
          "data": {
            "data": [
              {
                "id": 1,
                "date": "2026-02-15",
                "start_time": "17:00",
                "end_time": "19:00",
                "overtime_hours": "2:00",
                "overtime_type": "weekday",
                "overtime_type_label": "Hari Kerja",
                "overtime_amount": 50000,
                "formatted_amount": "Rp 50.000",
                "reason": "Top",
                "status": "pending",
                "status_label": "Menunggu",
                "created_at": "2026-02-15T18:00:00Z"
              }
            ]
          }
        }
      ''', 200),
      );

      final result = await datasource.getOvertimes();

      expect(result.length, 1);
      expect(result.first, isA<OvertimeModel>());
    });

    test('should throw Exception on failure', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => datasource.getOvertimes(), throwsException);
    });
  });

  group('createOvertime', () {
    test('should complete successfully when status code is 201', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.baseUrl}/overtimes'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 201));

      const request = OvertimeRequestModel(
        date: '2026-02-16',
        startTime: '18:00',
        endTime: '20:00',
        reason: 'Project',
      );

      await datasource.createOvertime(request);

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.baseUrl}/overtimes'),
          headers: any(named: 'headers'),
          body: json.encode(request.toJson()), // Verifying JSON body
        ),
      ).called(1);
    });
  });

  group('cancelOvertime', () {
    test('should complete successfully when status code is 200', () async {
      when(
        () => mockClient.post(
          Uri.parse('${Variables.baseUrl}/overtimes/1/cancel'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 200));

      await datasource.cancelOvertime(1);

      verify(
        () => mockClient.post(
          Uri.parse('${Variables.baseUrl}/overtimes/1/cancel'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });
  });

  group('getOvertimeSummary', () {
    test('should return OvertimeSummaryModel on success', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('''
        {
          "data": {
            "total_requests": 5,
            "approved_requests": 3,
            "pending_requests": 2,
            "total_hours": "10:30",
            "total_amount": 250000
          }
        }
      ''', 200),
      );

      final result = await datasource.getOvertimeSummary(month: 2, year: 2026);

      expect(result, isA<OvertimeSummaryModel>());
      expect(result.totalRequests, 5);
    });
  });
}
