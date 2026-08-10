import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_history/approval_history_bloc.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_history/approval_history_event.dart';
import 'package:gaji_pro/presentation/approval/bloc/approval_history/approval_history_state.dart';

import '../../../mocks/mock_approval_remote_datasource.dart';

void main() {
  late ApprovalHistoryBloc bloc;
  late MockApprovalRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockApprovalRemoteDatasource();
    bloc = ApprovalHistoryBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be ApprovalHistoryInitial', () {
    expect(bloc.state, equals(ApprovalHistoryInitial()));
  });

  blocTest<ApprovalHistoryBloc, ApprovalHistoryState>(
    'emits [Loading, Loaded] when LoadApprovalHistory succeeds',
    build: () => ApprovalHistoryBloc(mockDatasource),
    act: (bloc) => bloc.add(const LoadApprovalHistory()),
    expect: () => [
      ApprovalHistoryLoading(),
      isA<ApprovalHistoryLoaded>()
          .having((s) => s.history.length, 'history length', 1)
          .having((s) => s.hasReachedMax, 'hasReachedMax', false),
    ],
  );
}
