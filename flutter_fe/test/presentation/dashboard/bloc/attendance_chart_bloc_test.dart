import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/attendance_chart_bloc.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/attendance_chart_event.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/attendance_chart_state.dart';
import '../../../mocks/mock_dashboard_datasource.dart';

void main() {
  late AttendanceChartBloc attendanceChartBloc;
  late MockDashboardDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockDashboardDatasource();
    attendanceChartBloc = AttendanceChartBloc(datasource: mockDatasource);
  });

  tearDown(() {
    attendanceChartBloc.close();
  });

  test('initial state should be AttendanceChartInitial', () {
    expect(attendanceChartBloc.state, isA<AttendanceChartInitial>());
  });

  group('LoadAttendanceChart', () {
    final testChartData = AttendanceChartModel(
      labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
      datasets: [
        ChartDataset(
          label: 'Hadir',
          data: [1, 1, 1, 1, 1, 0, 0],
        ),
        ChartDataset(
          label: 'Terlambat',
          data: [0, 1, 0, 0, 0, 0, 0],
        ),
      ],
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Loaded] when LoadAttendanceChart is successful with default 7 days',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: 7))
            .thenAnswer((_) async => Right(testChartData));
        return attendanceChartBloc;
      },
      act: (bloc) => bloc.add(LoadAttendanceChart()),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartLoaded>().having(
          (s) => s.chartData.labels.length,
          'labels length',
          7,
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.getAttendanceChart(days: 7)).called(1);
      },
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Loaded] when LoadAttendanceChart is successful with 30 days',
      build: () {
        final testChartData30 = AttendanceChartModel(
          labels: List.generate(30, (i) => 'Day ${i + 1}'),
          datasets: [
            ChartDataset(
              label: 'Hadir',
              data: List.generate(30, (i) => i % 2 == 0 ? 1.0 : 0.0),
            ),
          ],
        );
        when(() => mockDatasource.getAttendanceChart(days: 30))
            .thenAnswer((_) async => Right(testChartData30));
        return attendanceChartBloc;
      },
      act: (bloc) => bloc.add(LoadAttendanceChart(days: 30)),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartLoaded>().having(
          (s) => s.chartData.labels.length,
          'labels length',
          30,
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.getAttendanceChart(days: 30)).called(1);
      },
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Error] when LoadAttendanceChart fails with network error',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: any(named: 'days')))
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return attendanceChartBloc;
      },
      act: (bloc) => bloc.add(LoadAttendanceChart()),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Error] when LoadAttendanceChart fails with authentication error',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: any(named: 'days')))
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return attendanceChartBloc;
      },
      act: (bloc) => bloc.add(LoadAttendanceChart()),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartError>().having(
          (e) => e.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });

  group('RefreshAttendanceChart', () {
    final testChartData = AttendanceChartModel(
      labels: ['Sen', 'Sel', 'Rab'],
      datasets: [
        ChartDataset(label: 'Hadir', data: [1, 1, 0]),
      ],
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Loaded] when RefreshAttendanceChart is successful',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: 7))
            .thenAnswer((_) async => Right(testChartData));
        return attendanceChartBloc;
      },
      seed: () => AttendanceChartLoaded(testChartData, days: 7),
      act: (bloc) => bloc.add(RefreshAttendanceChart()),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDatasource.getAttendanceChart(days: 7)).called(1);
      },
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Error] when RefreshAttendanceChart fails',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: any(named: 'days')))
            .thenAnswer((_) async => const Left('Server error'));
        return attendanceChartBloc;
      },
      seed: () => AttendanceChartLoaded(testChartData, days: 7),
      act: (bloc) => bloc.add(RefreshAttendanceChart()),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartError>().having(
          (e) => e.message,
          'message',
          'Server error',
        ),
      ],
    );
  });

  group('ChangeDays', () {
    final testChartData7 = AttendanceChartModel(
      labels: List.generate(7, (i) => 'Day ${i + 1}'),
      datasets: [ChartDataset(label: 'Hadir', data: List.filled(7, 1.0))],
    );

    final testChartData30 = AttendanceChartModel(
      labels: List.generate(30, (i) => 'Day ${i + 1}'),
      datasets: [ChartDataset(label: 'Hadir', data: List.filled(30, 1.0))],
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Loaded] when changing from 7 to 30 days',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: 30))
            .thenAnswer((_) async => Right(testChartData30));
        return attendanceChartBloc;
      },
      seed: () => AttendanceChartLoaded(testChartData7, days: 7),
      act: (bloc) => bloc.add(ChangeDays(30)),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartLoaded>().having(
          (s) => s.days,
          'days',
          30,
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.getAttendanceChart(days: 30)).called(1);
      },
    );

    blocTest<AttendanceChartBloc, AttendanceChartState>(
      'emits [Loading, Error] when ChangeDays fails',
      build: () {
        when(() => mockDatasource.getAttendanceChart(days: any(named: 'days')))
            .thenAnswer((_) async => const Left('Failed to load data'));
        return attendanceChartBloc;
      },
      seed: () => AttendanceChartLoaded(testChartData7, days: 7),
      act: (bloc) => bloc.add(ChangeDays(14)),
      expect: () => [
        isA<AttendanceChartLoading>(),
        isA<AttendanceChartError>().having(
          (e) => e.message,
          'message',
          'Failed to load data',
        ),
      ],
    );
  });
}
