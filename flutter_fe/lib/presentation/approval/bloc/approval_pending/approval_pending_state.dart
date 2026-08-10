import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/pending_approvals_model.dart';

abstract class ApprovalPendingState extends Equatable {
  const ApprovalPendingState();

  @override
  List<Object?> get props => [];
}

class ApprovalPendingInitial extends ApprovalPendingState {}

class ApprovalPendingLoading extends ApprovalPendingState {}

class ApprovalPendingLoaded extends ApprovalPendingState {
  final PendingApprovalsModel data;

  const ApprovalPendingLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ApprovalPendingError extends ApprovalPendingState {
  final String message;

  const ApprovalPendingError(this.message);

  @override
  List<Object?> get props => [message];
}
