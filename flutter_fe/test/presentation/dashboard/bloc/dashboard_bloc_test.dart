import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_state.dart';
import '../../../mocks/mock_dashboard_datasource.dart';

void main() {
  late DashboardBloc dashboardBloc;
  late MockDashboardDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockDashboardDatasource();
    dashboardBloc = DashboardBloc(datasource: mockDatasource);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  test('initial state should be DashboardInitial', () {
    expect(dashboardBloc.state, isA<DashboardInitial>());
  });

  group('LoadDashboard', () {
    final testAttendance = DashboardAttendance(
      todayStatus: 'present',
      clockIn: '08:02',
      clockOut: null,
      monthlyPresent: 18,
      monthlyAbsent: 1,
      monthlyLate: 2,
    );

    final testLeave = DashboardLeave(
      annualBalance: 12,
      annualUsed: 4,
      pendingRequests: 1,
    );

    final testPayroll = DashboardPayroll(
      lastPayslipMonth: 'Januari 2026',
      lastPayslipAmount: 5000000,
      ytdGross: 60000000,
      ytdNet: 55000000,
    );

    final testRequests = DashboardRequests(
      pendingOvertime: 2,
      pendingReimbursement: 1,
      pendingLeave: 0,
    );

    final testDashboardResponse = DashboardResponseModel(
      success: true,
      data: DashboardData(
        attendance: testAttendance,
        leave: testLeave,
        payroll: testPayroll,
        requests: testRequests,
      ),
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when LoadDashboard is successful',
      build: () {
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => Right(testDashboardResponse));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.data.attendance?.clockIn,
          'clockIn',
          '08:02',
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.getDashboard()).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when LoadDashboard fails with unauthenticated',
      build: () {
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having(
          (e) => e.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when network error occurs',
      build: () {
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when data is null',
      build: () {
        final emptyResponse = DashboardResponseModel(
          success: true,
          data: null,
        );
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => Right(emptyResponse));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having(
          (e) => e.message,
          'message',
          contains('tidak ditemukan'),
        ),
      ],
    );
  });

  group('RefreshDashboard', () {
    final testDashboardResponse = DashboardResponseModel(
      success: true,
      data: DashboardData(
        attendance: DashboardAttendance(
          todayStatus: 'present',
          clockIn: '08:02',
          monthlyPresent: 18,
        ),
        leave: DashboardLeave(
          annualBalance: 12,
          annualUsed: 4,
        ),
      ),
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when RefreshDashboard is successful',
      build: () {
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => Right(testDashboardResponse));
        return dashboardBloc;
      },
      seed: () => DashboardLoaded(testDashboardResponse.data!),
      act: (bloc) => bloc.add(RefreshDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when RefreshDashboard fails',
      build: () {
        when(() => mockDatasource.getDashboard())
            .thenAnswer((_) async => const Left('Session expired'));
        return dashboardBloc;
      },
      seed: () => DashboardLoaded(testDashboardResponse.data!),
      act: (bloc) => bloc.add(RefreshDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having(
          (e) => e.message,
          'message',
          'Session expired',
        ),
      ],
    );
  });
}
