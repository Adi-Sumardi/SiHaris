import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_today_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

void main() {
  late AttendanceTodayBloc bloc;
  late MockAttendanceRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAttendanceRemoteDatasource();
    bloc = AttendanceTodayBloc(datasource: mockDatasource);
  });

  const tAttendanceToday = AttendanceTodayModel(
    id: 1,
    date: '2023-10-27',
    status: 'present',
    statusLabel: 'Hadir',
  );

  group('AttendanceTodayBloc', () {
    test('initial state should be AttendanceTodayInitial', () {
      expect(bloc.state, AttendanceTodayInitial());
    });

    blocTest<AttendanceTodayBloc, AttendanceTodayState>(
      'emits [AttendanceTodayLoading, AttendanceTodayLoaded] when GetTodayAttendance is successful',
      build: () {
        when(
          () => mockDatasource.getTodayAttendance(),
        ).thenAnswer((_) async => const Right(tAttendanceToday));
        return bloc;
      },
      act: (bloc) => bloc.add(GetTodayStatus()),
      expect: () => [
        AttendanceTodayLoading(),
        const AttendanceTodayLoaded(tAttendanceToday),
      ],
    );

    blocTest<AttendanceTodayBloc, AttendanceTodayState>(
      'emits [AttendanceTodayLoading, AttendanceTodayError] when GetTodayAttendance fails',
      build: () {
        when(
          () => mockDatasource.getTodayAttendance(),
        ).thenAnswer((_) async => const Left('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetTodayStatus()),
      expect: () => [
        AttendanceTodayLoading(),
        const AttendanceTodayError('Failed'),
      ],
    );
  });
}
