import 'package:bloc/bloc.dart';
import '../../../../data/datasources/approval_remote_datasource.dart';
import 'approval_history_event.dart';
import 'approval_history_state.dart';

class ApprovalHistoryBloc
    extends Bloc<ApprovalHistoryEvent, ApprovalHistoryState> {
  final ApprovalRemoteDatasource datasource;
  int _currentPage = 1;

  ApprovalHistoryBloc(this.datasource) : super(ApprovalHistoryInitial()) {
    on<LoadApprovalHistory>(_onLoadApprovalHistory);
    on<RefreshApprovalHistory>(_onRefreshApprovalHistory);
    on<LoadMoreApprovalHistory>(_onLoadMoreApprovalHistory);
  }

  Future<void> _onLoadApprovalHistory(
    LoadApprovalHistory event,
    Emitter<ApprovalHistoryState> emit,
  ) async {
    emit(ApprovalHistoryLoading());
    try {
      _currentPage = 1;
      final history = await datasource.getApprovalHistory(page: _currentPage);
      emit(
        ApprovalHistoryLoaded(history: history, hasReachedMax: history.isEmpty),
      );
    } catch (e) {
      emit(ApprovalHistoryError(e.toString()));
    }
  }

  Future<void> _onRefreshApprovalHistory(
    RefreshApprovalHistory event,
    Emitter<ApprovalHistoryState> emit,
  ) async {
    emit(ApprovalHistoryLoading());
    try {
      _currentPage = 1;
      final history = await datasource.getApprovalHistory(page: _currentPage);
      emit(
        ApprovalHistoryLoaded(history: history, hasReachedMax: history.isEmpty),
      );
    } catch (e) {
      emit(ApprovalHistoryError(e.toString()));
    }
  }

  Future<void> _onLoadMoreApprovalHistory(
    LoadMoreApprovalHistory event,
    Emitter<ApprovalHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ApprovalHistoryLoaded || currentState.hasReachedMax) {
      return;
    }

    try {
      _currentPage++;
      final newHistory = await datasource.getApprovalHistory(
        page: _currentPage,
      );

      if (newHistory.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        emit(
          ApprovalHistoryLoaded(
            history: [...currentState.history, ...newHistory],
            hasReachedMax: false,
          ),
        );
      }
    } catch (e) {
      emit(ApprovalHistoryError(e.toString()));
    }
  }
}
