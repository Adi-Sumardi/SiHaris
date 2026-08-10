import 'package:bloc/bloc.dart';
import '../../../../data/datasources/approval_remote_datasource.dart';
import 'approval_pending_event.dart';
import 'approval_pending_state.dart';

class ApprovalPendingBloc
    extends Bloc<ApprovalPendingEvent, ApprovalPendingState> {
  final ApprovalRemoteDatasource datasource;

  ApprovalPendingBloc(this.datasource) : super(ApprovalPendingInitial()) {
    on<LoadPendingApprovals>(_onLoadPendingApprovals);
    on<RefreshPendingApprovals>(_onRefreshPendingApprovals);
  }

  Future<void> _onLoadPendingApprovals(
    LoadPendingApprovals event,
    Emitter<ApprovalPendingState> emit,
  ) async {
    emit(ApprovalPendingLoading());
    try {
      final data = await datasource.getPendingApprovals();
      emit(ApprovalPendingLoaded(data));
    } catch (e) {
      emit(ApprovalPendingError(e.toString()));
    }
  }

  Future<void> _onRefreshPendingApprovals(
    RefreshPendingApprovals event,
    Emitter<ApprovalPendingState> emit,
  ) async {
    emit(ApprovalPendingLoading());
    try {
      final data = await datasource.getPendingApprovals();
      emit(ApprovalPendingLoaded(data));
    } catch (e) {
      emit(ApprovalPendingError(e.toString()));
    }
  }
}
