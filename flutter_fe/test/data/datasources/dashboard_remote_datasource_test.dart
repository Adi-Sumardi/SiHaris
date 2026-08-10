import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/dashboard_remote_datasource.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import '../../mocks/mock_http_client.dart';
import '../../mocks/mock_auth_local_datasource.dart';

void main() {
  late DashboardRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLocalDatasource = MockAuthLocalDatasource();
    datasource = DashboardRemoteDatasource(
      client: mockHttpClient,
      localDatasource: mockLocalDatasource,
    );
  });

  group('getDashboard', () {
    const testToken = 'test_token_123';

    // New API structure sesuai dengan API docs
    final dashboardResponse = {
      'success': true,
      'data': {
        'attendance': {
          'today_status': 'present',
          'clock_in': '08:02',
          'clock_out': null,
          'monthly_present': 18,
          'monthly_absent': 1,
          'monthly_late': 2,
        },
        'leave': {
          'annual_balance': 12.0,
          'annual_used': 4.0,
          'pending_requests': 1,
        },
        'payroll': {
          'last_payslip_month': 'Januari 2026',
          'last_payslip_amount': 5000000,
          'ytd_gross': 60000000,
          'ytd_net': 55000000,
        },
        'requests': {
          'pending_overtime': 2,
          'pending_reimbursement': 1,
          'pending_leave': 0,
        },
      },
    };

    test('should return DashboardResponseModel when getDashboard is successful',
        () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(dashboardResponse), 200),
      );

      // Act
      final result = await datasource.getDashboard();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) {
          expect(r.success, true);
          expect(r.data, isNotNull);
          // New structure assertions
          expect(r.data!.attendance?.clockIn, '08:02');
          expect(r.data!.attendance?.todayStatus, 'present');
          expect(r.data!.attendance?.monthlyPresent, 18);
          expect(r.data!.leave?.annualBalance, 12.0);
          expect(r.data!.leave?.annualUsed, 4.0);
          expect(r.data!.leave?.remaining, 8.0); // 12 - 4
          expect(r.data!.payroll?.lastPayslipAmount, 5000000);
          expect(r.data!.requests?.pendingOvertime, 2);
          expect(r.data!.requests?.totalPending, 3); // 2 + 1 + 0
        },
      );

      verify(() => mockHttpClient.get(
            Uri.parse(Variables.dashboard),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $testToken',
            },
          )).called(1);
    });

    test('should return error when getDashboard fails with 401', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Unauthenticated'}),
          401,
        ),
      );

      // Act
      final result = await datasource.getDashboard();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Unauthenticated'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when network exception occurs', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenThrow(Exception('No internet connection'));

      // Act
      final result = await datasource.getDashboard();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('Terjadi kesalahan'), true),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when token is null', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await datasource.getDashboard();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('belum login'), true),
        (r) => fail('Should not return Right'),
      );
    });

    test('should handle partial data in response', () async {
      // Arrange - Response with only attendance data
      final partialResponse = {
        'success': true,
        'data': {
          'attendance': {
            'today_status': 'absent',
            'clock_in': null,
            'clock_out': null,
            'monthly_present': 10,
            'monthly_absent': 5,
            'monthly_late': 0,
          },
        },
      };

      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(partialResponse), 200),
      );

      // Act
      final result = await datasource.getDashboard();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) {
          expect(r.data!.attendance?.todayStatus, 'absent');
          expect(r.data!.attendance?.hasClockedIn, false);
          expect(r.data!.leave, isNull);
          expect(r.data!.payroll, isNull);
          expect(r.data!.requests, isNull);
        },
      );
    });
  });

  group('getQuickStats', () {
    const testToken = 'test_token_123';

    // New API structure sesuai dengan API docs
    final quickStatsResponse = {
      'success': true,
      'data': {
        'total_working_days_this_month': 22,
        'total_present_days': 18,
        'total_absent_days': 2,
        'total_leave_days': 2,
        'total_late_count': 3,
        'total_overtime_hours': 12.5,
        'attendance_percentage': 81.8,
      },
    };

    test('should return QuickStatsModel when getQuickStats is successful',
        () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(quickStatsResponse), 200),
      );

      // Act
      final result = await datasource.getQuickStats();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) {
          expect(r.totalWorkingDaysThisMonth, 22);
          expect(r.totalPresentDays, 18);
          expect(r.totalAbsentDays, 2);
          expect(r.totalLeaveDays, 2);
          expect(r.totalLateCount, 3);
          expect(r.totalOvertimeHours, 12.5);
          expect(r.attendancePercentage, 81.8);
          // Helper getters
          expect(r.attendanceDisplay, '18/22 Hari');
          expect(r.percentageDisplay, '81.8%');
        },
      );

      verify(() => mockHttpClient.get(
            Uri.parse(Variables.dashboardQuickStats),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $testToken',
            },
          )).called(1);
    });

    test('should return error when getQuickStats fails', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Server error'}),
          500,
        ),
      );

      // Act
      final result = await datasource.getQuickStats();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Server error'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when data is null', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'data': null}),
          200,
        ),
      );

      // Act
      final result = await datasource.getQuickStats();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('tidak ditemukan'), true),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when token is null', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await datasource.getQuickStats();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('belum login'), true),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('getAttendanceChart', () {
    const testToken = 'test_token_123';

    final chartResponse = {
      'success': true,
      'data': {
        'labels': ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
        'datasets': [
          {
            'label': 'Hadir',
            'data': [1, 1, 1, 1, 1, 0, 0],
          },
          {
            'label': 'Terlambat',
            'data': [0, 1, 0, 0, 0, 0, 0],
          },
        ],
      },
    };

    test(
        'should return AttendanceChartModel when getAttendanceChart is successful',
        () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(chartResponse), 200),
      );

      // Act
      final result = await datasource.getAttendanceChart(days: 7);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) {
          expect(r.labels.length, 7);
          expect(r.labels.first, 'Sen');
          expect(r.datasets.length, 2);
          expect(r.datasets[0].label, 'Hadir');
          expect(r.datasets[0].data.length, 7);
          expect(r.datasets[1].label, 'Terlambat');
        },
      );

      // Verify URL includes days query parameter
      verify(() => mockHttpClient.get(
            Uri.parse(Variables.dashboardAttendanceChart)
                .replace(queryParameters: {'days': '7'}),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $testToken',
            },
          )).called(1);
    });

    test('should return error when getAttendanceChart fails', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Server error'}),
          500,
        ),
      );

      // Act
      final result = await datasource.getAttendanceChart();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Server error'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when token is null', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await datasource.getAttendanceChart();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('belum login'), true),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when data is null', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'data': null}),
          200,
        ),
      );

      // Act
      final result = await datasource.getAttendanceChart();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('tidak ditemukan'), true),
        (r) => fail('Should not return Right'),
      );
    });
  });
}
