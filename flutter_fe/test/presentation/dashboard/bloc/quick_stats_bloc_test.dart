import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_bloc.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_event.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_state.dart';
import '../../../mocks/mock_dashboard_datasource.dart';

void main() {
  late QuickStatsBloc quickStatsBloc;
  late MockDashboardDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockDashboardDatasource();
    quickStatsBloc = QuickStatsBloc(datasource: mockDatasource);
  });

  tearDown(() {
    quickStatsBloc.close();
  });

  test('initial state should be QuickStatsInitial', () {
    expect(quickStatsBloc.state, isA<QuickStatsInitial>());
  });

  group('LoadQuickStats', () {
    final testStats = QuickStatsModel(
      totalWorkingDaysThisMonth: 22,
      totalPresentDays: 18,
      totalAbsentDays: 2,
      totalLeaveDays: 2,
      totalLateCount: 3,
      totalOvertimeHours: 12.5,
      attendancePercentage: 81.8,
    );

    blocTest<QuickStatsBloc, QuickStatsState>(
      'emits [Loading, Loaded] when LoadQuickStats is successful',
      build: () {
        when(() => mockDatasource.getQuickStats())
            .thenAnswer((_) async => Right(testStats));
        return quickStatsBloc;
      },
      act: (bloc) => bloc.add(LoadQuickStats()),
      expect: () => [
        isA<QuickStatsLoading>(),
        isA<QuickStatsLoaded>().having(
          (s) => s.stats.totalPresentDays,
          'totalPresentDays',
          18,
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.getQuickStats()).called(1);
      },
    );

    blocTest<QuickStatsBloc, QuickStatsState>(
      'emits [Loading, Error] when LoadQuickStats fails with network error',
      build: () {
        when(() => mockDatasource.getQuickStats())
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return quickStatsBloc;
      },
      act: (bloc) => bloc.add(LoadQuickStats()),
      expect: () => [
        isA<QuickStatsLoading>(),
        isA<QuickStatsError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<QuickStatsBloc, QuickStatsState>(
      'emits [Loading, Error] when LoadQuickStats fails with authentication error',
      build: () {
        when(() => mockDatasource.getQuickStats())
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return quickStatsBloc;
      },
      act: (bloc) => bloc.add(LoadQuickStats()),
      expect: () => [
        isA<QuickStatsLoading>(),
        isA<QuickStatsError>().having(
          (e) => e.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });

  group('RefreshQuickStats', () {
    final testStats = QuickStatsModel(
      totalWorkingDaysThisMonth: 22,
      totalPresentDays: 20,
      totalAbsentDays: 1,
      totalLeaveDays: 1,
      totalLateCount: 2,
      totalOvertimeHours: 8.0,
      attendancePercentage: 90.9,
    );

    blocTest<QuickStatsBloc, QuickStatsState>(
      'emits [Loading, Loaded] when RefreshQuickStats is successful',
      build: () {
        when(() => mockDatasource.getQuickStats())
            .thenAnswer((_) async => Right(testStats));
        return quickStatsBloc;
      },
      seed: () => QuickStatsLoaded(testStats),
      act: (bloc) => bloc.add(RefreshQuickStats()),
      expect: () => [
        isA<QuickStatsLoading>(),
        isA<QuickStatsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDatasource.getQuickStats()).called(1);
      },
    );

    blocTest<QuickStatsBloc, QuickStatsState>(
      'emits [Loading, Error] when RefreshQuickStats fails',
      build: () {
        when(() => mockDatasource.getQuickStats())
            .thenAnswer((_) async => const Left('Server error'));
        return quickStatsBloc;
      },
      seed: () => QuickStatsLoaded(testStats),
      act: (bloc) => bloc.add(RefreshQuickStats()),
      expect: () => [
        isA<QuickStatsLoading>(),
        isA<QuickStatsError>().having(
          (e) => e.message,
          'message',
          'Server error',
        ),
      ],
    );
  });
}
