import 'package:equatable/equatable.dart';

abstract class ApprovalActionState extends Equatable {
  const ApprovalActionState();

  @override
  List<Object?> get props => [];
}

class ApprovalActionInitial extends ApprovalActionState {}

class ApprovalActionLoading extends ApprovalActionState {}

class ApprovalActionSuccess extends ApprovalActionState {
  final String message;

  const ApprovalActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ApprovalActionError extends ApprovalActionState {
  final String message;

  const ApprovalActionError(this.message);

  @override
  List<Object?> get props => [message];
}
