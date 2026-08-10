part of 'reimbursement_request_bloc.dart';

abstract class ReimbursementRequestState extends Equatable {
  const ReimbursementRequestState();

  @override
  List<Object?> get props => [];
}

class ReimbursementRequestInitial extends ReimbursementRequestState {}

class ReimbursementRequestSubmitting extends ReimbursementRequestState {}

class ReimbursementRequestSuccess extends ReimbursementRequestState {
  final ReimbursementModel reimbursement;

  const ReimbursementRequestSuccess(this.reimbursement);

  @override
  List<Object?> get props => [reimbursement];
}

class ReimbursementRequestError extends ReimbursementRequestState {
  final String message;

  const ReimbursementRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
