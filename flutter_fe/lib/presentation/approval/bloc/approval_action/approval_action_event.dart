import 'package:equatable/equatable.dart';

abstract class ApprovalActionEvent extends Equatable {
  const ApprovalActionEvent();

  @override
  List<Object?> get props => [];
}

class ApproveLeaveRequest extends ApprovalActionEvent {
  final int id;
  final String? notes;

  const ApproveLeaveRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}

class RejectLeaveRequest extends ApprovalActionEvent {
  final int id;
  final String notes;

  const RejectLeaveRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}

class ApproveOvertimeRequest extends ApprovalActionEvent {
  final int id;
  final String? notes;

  const ApproveOvertimeRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}

class RejectOvertimeRequest extends ApprovalActionEvent {
  final int id;
  final String notes;

  const RejectOvertimeRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}

class ApproveReimbursementRequest extends ApprovalActionEvent {
  final int id;
  final String? notes;

  const ApproveReimbursementRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}

class RejectReimbursementRequest extends ApprovalActionEvent {
  final int id;
  final String notes;

  const RejectReimbursementRequest(this.id, this.notes);

  @override
  List<Object?> get props => [id, notes];
}
