import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';

class MockLeaveRemoteDatasource extends Mock implements LeaveRemoteDatasource {}

void main() {
  late LeaveBalanceBloc bloc;
  late MockLeaveRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLeaveRemoteDatasource();
    bloc = LeaveBalanceBloc(mockDatasource);
  });

  const tLeaveBalances = [
    LeaveBalanceModel(
      leaveTypeId: 1,
      leaveTypeName: 'Cuti Tahunan',
      year: 2026,
      entitledDays: 12,
      usedDays: 2,
      pendingDays: 1,
      remainingDays: 9,
    ),
    LeaveBalanceModel(
      leaveTypeId: 2,
      leaveTypeName: 'Cuti Sakit',
      year: 2026,
      entitledDays: 14,
      usedDays: 0,
      pendingDays: 0,
      remainingDays: 14,
    ),
  ];

  test('initial state should be LeaveBalanceInitial', () {
    expect(bloc.state, LeaveBalanceInitial());
  });

  blocTest<LeaveBalanceBloc, LeaveBalanceState>(
    'emits [LeaveBalanceLoading, LeaveBalanceLoaded] when GetLeaveBalance is added and fetch is successful',
    build: () {
      when(
        () => mockDatasource.getLeaveBalances(),
      ).thenAnswer((_) async => tLeaveBalances);
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveBalance()),
    expect: () => [
      LeaveBalanceLoading(),
      const LeaveBalanceLoaded(tLeaveBalances),
    ],
  );

  blocTest<LeaveBalanceBloc, LeaveBalanceState>(
    'emits [LeaveBalanceLoading, LeaveBalanceError] when GetLeaveBalance is added and fetch fails',
    build: () {
      when(
        () => mockDatasource.getLeaveBalances(),
      ).thenThrow(Exception('Failed to fetch'));
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveBalance()),
    expect: () => [
      LeaveBalanceLoading(),
      const LeaveBalanceError('Failed to fetch'),
    ],
  );

  blocTest<LeaveBalanceBloc, LeaveBalanceState>(
    'emits [LeaveBalanceLoading, LeaveBalanceLoaded] with empty list when no balances',
    build: () {
      when(
        () => mockDatasource.getLeaveBalances(),
      ).thenAnswer((_) async => []);
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveBalance()),
    expect: () => [
      LeaveBalanceLoading(),
      const LeaveBalanceLoaded([]),
    ],
  );
}
