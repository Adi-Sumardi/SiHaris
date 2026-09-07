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

  blocTest<LeaveListBloc, LeaveListState>(
    'does not mark a full 15-item page as the last page (backend page size is 15, not 10)',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1),
      ).thenAnswer((_) async => List.filled(15, tLeaveModel));
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveList()),
    expect: () => [
      LeaveListLoading(),
      LeaveListLoaded(List.filled(15, tLeaveModel), hasReachedMax: false),
    ],
  );

  blocTest<LeaveListBloc, LeaveListState>(
    'marks a page with fewer than 15 items as the last page',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1),
      ).thenAnswer((_) async => List.filled(12, tLeaveModel));
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveList()),
    expect: () => [
      LeaveListLoading(),
      LeaveListLoaded(List.filled(12, tLeaveModel), hasReachedMax: true),
    ],
  );

  blocTest<LeaveListBloc, LeaveListState>(
    'appends page 2 results to the existing list instead of replacing it',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1),
      ).thenAnswer((_) async => [tLeaveModel]);
      when(
        () => mockDatasource.getLeaves(page: 2),
      ).thenAnswer((_) async => [tLeaveModel, tLeaveModel]);
      return bloc;
    },
    act: (bloc) async {
      bloc.add(GetLeaveList());
      await Future.delayed(Duration.zero);
      bloc.add(GetLeaveList(page: 2));
    },
    expect: () => [
      LeaveListLoading(),
      const LeaveListLoaded([tLeaveModel], hasReachedMax: true),
      const LeaveListLoaded([
        tLeaveModel,
        tLeaveModel,
        tLeaveModel,
      ], hasReachedMax: true),
    ],
  );

  blocTest<LeaveListBloc, LeaveListState>(
    'forwards status and year filters to the datasource',
    build: () {
      when(
        () => mockDatasource.getLeaves(page: 1, status: 'approved', year: 2026),
      ).thenAnswer((_) async => [tLeaveModel]);
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveList(status: 'approved', year: 2026)),
    verify: (_) {
      verify(
        () => mockDatasource.getLeaves(page: 1, status: 'approved', year: 2026),
      ).called(1);
    },
  );
}
