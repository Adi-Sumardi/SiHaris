import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_pending/approval_pending_bloc.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_pending/approval_pending_event.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_pending/approval_pending_state.dart';

import '../../../mocks/mock_approval_remote_datasource.dart';

void main() {
  late ApprovalPendingBloc bloc;
  late MockApprovalRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockApprovalRemoteDatasource();
    bloc = ApprovalPendingBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be ApprovalPendingInitial', () {
    expect(bloc.state, equals(ApprovalPendingInitial()));
  });

  blocTest<ApprovalPendingBloc, ApprovalPendingState>(
    'emits [Loading, Loaded] when LoadPendingApprovals succeeds',
    build: () => ApprovalPendingBloc(mockDatasource),
    act: (bloc) => bloc.add(const LoadPendingApprovals()),
    expect: () => [
      ApprovalPendingLoading(),
      isA<ApprovalPendingLoaded>().having(
        (s) => s.data.totalPending,
        'totalPending',
        0,
      ),
    ],
  );

  blocTest<ApprovalPendingBloc, ApprovalPendingState>(
    'emits [Loading, Loaded] when RefreshPendingApprovals succeeds',
    build: () => ApprovalPendingBloc(mockDatasource),
    act: (bloc) => bloc.add(const RefreshPendingApprovals()),
    expect: () => [
      ApprovalPendingLoading(),
      isA<ApprovalPendingLoaded>().having(
        (s) => s.data.totalPending,
        'totalPending',
        0,
      ),
    ],
  );
}
