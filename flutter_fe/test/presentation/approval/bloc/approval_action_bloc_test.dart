import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_action/approval_action_bloc.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_action/approval_action_event.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_action/approval_action_state.dart';

import '../../../mocks/mock_approval_remote_datasource.dart';

void main() {
  late ApprovalActionBloc bloc;
  late MockApprovalRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockApprovalRemoteDatasource();
    bloc = ApprovalActionBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be ApprovalActionInitial', () {
    expect(bloc.state, equals(ApprovalActionInitial()));
  });

  blocTest<ApprovalActionBloc, ApprovalActionState>(
    'emits [Loading, Success] when ApproveLeaveRequest succeeds',
    build: () => ApprovalActionBloc(mockDatasource),
    act: (bloc) => bloc.add(const ApproveLeaveRequest(1, 'Approved')),
    expect: () => [
      ApprovalActionLoading(),
      isA<ApprovalActionSuccess>().having(
        (s) => s.message,
        'message',
        contains('approved'),
      ),
    ],
  );

  blocTest<ApprovalActionBloc, ApprovalActionState>(
    'emits [Loading, Success] when RejectLeaveRequest succeeds',
    build: () => ApprovalActionBloc(mockDatasource),
    act: (bloc) => bloc.add(const RejectLeaveRequest(1, 'Not enough quota')),
    expect: () => [
      ApprovalActionLoading(),
      isA<ApprovalActionSuccess>().having(
        (s) => s.message,
        'message',
        contains('rejected'),
      ),
    ],
  );
}
