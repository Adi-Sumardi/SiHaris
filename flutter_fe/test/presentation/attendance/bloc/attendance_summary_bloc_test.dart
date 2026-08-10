import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_summary_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

void main() {
  late AttendanceSummaryBloc bloc;
  late MockAttendanceRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAttendanceRemoteDatasource();
    bloc = AttendanceSummaryBloc(datasource: mockDatasource);
  });

  const tSummary = AttendanceSummaryModel(
    totalWorkingDays: 20,
    present: 18,
    absent: 1,
    late: 1,
    leave: 0,
    workingHours: '160:00',
    overtimeHours: '05:30',
  );

  group('AttendanceSummaryBloc', () {
    test('initial state should be AttendanceSummaryInitial', () {
      expect(bloc.state, AttendanceSummaryInitial());
    });

    blocTest<AttendanceSummaryBloc, AttendanceSummaryState>(
      'emits [AttendanceSummaryLoading, AttendanceSummaryLoaded] when GetAttendanceSummary is successful',
      build: () {
        when(
          () => mockDatasource.getSummary(month: 10, year: 2023),
        ).thenAnswer((_) async => const Right(tSummary));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const GetAttendanceSummary(month: 10, year: 2023)),
      expect: () => [
        AttendanceSummaryLoading(),
        const AttendanceSummaryLoaded(tSummary),
      ],
    );

    blocTest<AttendanceSummaryBloc, AttendanceSummaryState>(
      'emits [AttendanceSummaryLoading, AttendanceSummaryError] when GetAttendanceSummary fails',
      build: () {
        when(
          () => mockDatasource.getSummary(month: 10, year: 2023),
        ).thenAnswer((_) async => const Left('Failed'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const GetAttendanceSummary(month: 10, year: 2023)),
      expect: () => [
        AttendanceSummaryLoading(),
        const AttendanceSummaryError('Failed'),
      ],
    );
  });
}
