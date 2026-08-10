import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';

class MockLeaveRemoteDatasource extends Mock implements LeaveRemoteDatasource {}

void main() {
  late LeaveCrudBloc bloc;
  late MockLeaveRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLeaveRemoteDatasource();
    bloc = LeaveCrudBloc(mockDatasource);
  });

  final tLeaveRequest = LeaveRequestModel(
    leaveTypeId: 1,
    startDate: '2024-02-20',
    endDate: '2024-02-21',
    reason: 'Sakit',
    emergencyContact: '08123456789',
  );

  test('initial state should be LeaveCrudInitial', () {
    expect(bloc.state, LeaveCrudInitial());
  });

  group('CreateLeave', () {
    blocTest<LeaveCrudBloc, LeaveCrudState>(
      'emits [LeaveCrudLoading, LeaveCrudSuccess] when CreateLeave is added and creation is successful',
      build: () {
        when(
          () => mockDatasource.createLeaveRequest(tLeaveRequest),
        ).thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(CreateLeave(tLeaveRequest)),
      expect: () => [
        LeaveCrudLoading(),
        const LeaveCrudSuccess('Berhasil membuat pengajuan cuti'),
      ],
    );

    blocTest<LeaveCrudBloc, LeaveCrudState>(
      'emits [LeaveCrudLoading, LeaveCrudFailure] when CreateLeave is added and creation fails',
      build: () {
        when(
          () => mockDatasource.createLeaveRequest(tLeaveRequest),
        ).thenThrow(Exception('Failed to create'));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateLeave(tLeaveRequest)),
      expect: () => [
        LeaveCrudLoading(),
        const LeaveCrudFailure('Failed to create'),
      ],
    );
  });

  group('CancelLeave', () {
    blocTest<LeaveCrudBloc, LeaveCrudState>(
      'emits [LeaveCrudLoading, LeaveCrudSuccess] when CancelLeave is added and cancellation is successful',
      build: () {
        when(
          () => mockDatasource.cancelLeaveRequest(1, 'Changed mind'),
        ).thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(CancelLeave(1, 'Changed mind')),
      expect: () => [
        LeaveCrudLoading(),
        const LeaveCrudSuccess('Berhasil membatalkan pengajuan cuti'),
      ],
    );

    blocTest<LeaveCrudBloc, LeaveCrudState>(
      'emits [LeaveCrudLoading, LeaveCrudFailure] when CancelLeave is added and cancellation fails',
      build: () {
        when(
          () => mockDatasource.cancelLeaveRequest(1, 'Changed mind'),
        ).thenThrow(Exception('Failed to cancel'));
        return bloc;
      },
      act: (bloc) => bloc.add(CancelLeave(1, 'Changed mind')),
      expect: () => [
        LeaveCrudLoading(),
        const LeaveCrudFailure('Failed to cancel'),
      ],
    );
  });
}
