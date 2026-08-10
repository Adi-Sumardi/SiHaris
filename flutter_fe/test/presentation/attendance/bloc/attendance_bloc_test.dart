import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

void main() {
  late AttendanceBloc bloc;
  late MockAttendanceRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAttendanceRemoteDatasource();
    bloc = AttendanceBloc(datasource: mockDatasource);
  });

  group('AttendanceBloc', () {
    test('initial state should be AttendanceInitial', () {
      expect(bloc.state, AttendanceInitial());
    });

    final tClockInRequest = ClockInRequestModel(
      latitude: -6.2,
      longitude: 106.8,
      officeLocationId: 1,
    );

    final tClockOutRequest = ClockOutRequestModel(
      latitude: -6.2,
      longitude: 106.8,
      officeLocationId: 1,
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emits [AttendanceLoading, AttendanceSuccess] when ClockIn is successful',
      build: () {
        when(
          () => mockDatasource.clockIn(tClockInRequest),
        ).thenAnswer((_) async => const Right({'message': 'Success'}));
        return bloc;
      },
      act: (bloc) => bloc.add(AttendanceClockIn(tClockInRequest)),
      expect: () => [AttendanceLoading(), AttendanceSuccess('Success')],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emits [AttendanceLoading, AttendanceFailure] when ClockIn fails',
      build: () {
        when(
          () => mockDatasource.clockIn(tClockInRequest),
        ).thenAnswer((_) async => const Left('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(AttendanceClockIn(tClockInRequest)),
      expect: () => [AttendanceLoading(), AttendanceFailure('Failed')],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emits [AttendanceLoading, AttendanceSuccess] when ClockOut is successful',
      build: () {
        when(
          () => mockDatasource.clockOut(tClockOutRequest),
        ).thenAnswer((_) async => const Right({'message': 'Success'}));
        return bloc;
      },
      act: (bloc) => bloc.add(AttendanceClockOut(tClockOutRequest)),
      expect: () => [AttendanceLoading(), AttendanceSuccess('Success')],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emits [AttendanceLoading, AttendanceFailure] when ClockOut fails',
      build: () {
        when(
          () => mockDatasource.clockOut(tClockOutRequest),
        ).thenAnswer((_) async => const Left('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(AttendanceClockOut(tClockOutRequest)),
      expect: () => [AttendanceLoading(), AttendanceFailure('Failed')],
    );
  });
}
