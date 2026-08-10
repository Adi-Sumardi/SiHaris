part of 'reimbursement_detail_bloc.dart';

abstract class ReimbursementDetailState extends Equatable {
  const ReimbursementDetailState();

  @override
  List<Object?> get props => [];
}

class ReimbursementDetailInitial extends ReimbursementDetailState {}

class ReimbursementDetailLoading extends ReimbursementDetailState {}

class ReimbursementDetailLoaded extends ReimbursementDetailState {
  final ReimbursementModel reimbursement;

  const ReimbursementDetailLoaded(this.reimbursement);

  @override
  List<Object?> get props => [reimbursement];
}

class ReimbursementDetailError extends ReimbursementDetailState {
  final String message;

  const ReimbursementDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
