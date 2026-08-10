import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_history_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

void main() {
  late AttendanceHistoryBloc bloc;
  late MockAttendanceRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAttendanceRemoteDatasource();
    bloc = AttendanceHistoryBloc(datasource: mockDatasource);
  });

  final tHistoryList = [
    const AttendanceHistoryModel(
      id: 1,
      date: '2023-10-27',
      status: 'present',
      statusLabel: 'Hadir',
    ),
  ];

  group('AttendanceHistoryBloc', () {
    test('initial state should be AttendanceHistoryInitial', () {
      expect(bloc.state, AttendanceHistoryInitial());
    });

    blocTest<AttendanceHistoryBloc, AttendanceHistoryState>(
      'emits [AttendanceHistoryLoading, AttendanceHistoryLoaded] when GetAttendanceHistory is successful',
      build: () {
        when(
          () => mockDatasource.getHistory(
            page: any(named: 'page'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => Right(tHistoryList));
        return bloc;
      },
      act: (bloc) => bloc.add(GetAttendanceHistory()),
      expect: () => [
        AttendanceHistoryLoading(),
        AttendanceHistoryLoaded(tHistoryList),
      ],
    );

    blocTest<AttendanceHistoryBloc, AttendanceHistoryState>(
      'emits [AttendanceHistoryLoading, AttendanceHistoryError] when GetAttendanceHistory fails',
      build: () {
        when(
          () => mockDatasource.getHistory(
            page: any(named: 'page'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => const Left('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetAttendanceHistory()),
      expect: () => [
        AttendanceHistoryLoading(),
        AttendanceHistoryError('Failed'),
      ],
    );
  });
}
