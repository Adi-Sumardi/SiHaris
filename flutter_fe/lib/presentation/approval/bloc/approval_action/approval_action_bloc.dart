import 'package:bloc/bloc.dart';
import '../../../../data/datasources/approval_remote_datasource.dart';
import 'approval_action_event.dart';
import 'approval_action_state.dart';

class ApprovalActionBloc
    extends Bloc<ApprovalActionEvent, ApprovalActionState> {
  final ApprovalRemoteDatasource datasource;

  ApprovalActionBloc(this.datasource) : super(ApprovalActionInitial()) {
    on<ApproveLeaveRequest>(_onApproveLeaveRequest);
    on<RejectLeaveRequest>(_onRejectLeaveRequest);
    on<ApproveOvertimeRequest>(_onApproveOvertimeRequest);
    on<RejectOvertimeRequest>(_onRejectOvertimeRequest);
    on<ApproveReimbursementRequest>(_onApproveReimbursementRequest);
    on<RejectReimbursementRequest>(_onRejectReimbursementRequest);
  }

  Future<void> _onApproveLeaveRequest(
    ApproveLeaveRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.approveLeave(event.id, event.notes);
      emit(const ApprovalActionSuccess('Leave request approved successfully'));
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }

  Future<void> _onRejectLeaveRequest(
    RejectLeaveRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.rejectLeave(event.id, event.notes);
      emit(const ApprovalActionSuccess('Leave request rejected successfully'));
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }

  Future<void> _onApproveOvertimeRequest(
    ApproveOvertimeRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.approveOvertime(event.id, event.notes);
      emit(
        const ApprovalActionSuccess('Overtime request approved successfully'),
      );
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }

  Future<void> _onRejectOvertimeRequest(
    RejectOvertimeRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.rejectOvertime(event.id, event.notes);
      emit(
        const ApprovalActionSuccess('Overtime request rejected successfully'),
      );
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }

  Future<void> _onApproveReimbursementRequest(
    ApproveReimbursementRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.approveReimbursement(event.id, event.notes);
      emit(const ApprovalActionSuccess('Reimbursement approved successfully'));
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }

  Future<void> _onRejectReimbursementRequest(
    RejectReimbursementRequest event,
    Emitter<ApprovalActionState> emit,
  ) async {
    emit(ApprovalActionLoading());
    try {
      await datasource.rejectReimbursement(event.id, event.notes);
      emit(const ApprovalActionSuccess('Reimbursement rejected successfully'));
    } catch (e) {
      emit(ApprovalActionError(e.toString()));
    }
  }
}
