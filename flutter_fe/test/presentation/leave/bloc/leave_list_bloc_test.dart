import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_list/leave_list_bloc.dart';

class MockLeaveRemoteDatasource extends Mock implements LeaveRemoteDatasource {}

void main() {
  late LeaveListBloc bloc;
  late MockLeaveRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLeaveRemoteDatasource();
    bloc = LeaveListBloc(mockDatasource);
  });

  const tLeaveModel = LeaveModel(
    id: 1,
    requestNumber: 'LV-2024-001',
    leaveType: LeaveTypeModel(
      id: 1,
      name: 'Cuti Tahunan',
      quota: 12,
      isPaid: true,
      requiresAttachment: false,
    ),
    startDate: '2024-02-20',
    endDate: '2024-02-21',
    totalDays: 2,
    isHalfDay: false,
    status: 'pending',
    statusLabel: 'Menunggu Persetujuan',
    createdAt: '2024-02-01',
  );

  test('initial state should be LeaveListInitial', () {
    expect(bloc.state, LeaveListInitial());
  });

  blocTest<LeaveListBloc, LeaveListState>(
    'emits [LeaveListLoading, LeaveListLoaded] when GetLeaveList is added and fetch is successful',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1),
      ).thenAnswer((_) async => [tLeaveModel]);
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveList()),
    expect: () => [
      LeaveListLoading(),
      const LeaveListLoaded([tLeaveModel], hasReachedMax: true),
    ],
  );

  blocTest<LeaveListBloc, LeaveListState>(
    'emits [LeaveListLoading, LeaveListError] when GetLeaveList is added and fetch fails',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1),
      ).thenThrow(Exception('Failed to fetch'));
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveList()),
    expect: () => [LeaveListLoading(), const LeaveListError('Failed to fetch')],
  );
}
