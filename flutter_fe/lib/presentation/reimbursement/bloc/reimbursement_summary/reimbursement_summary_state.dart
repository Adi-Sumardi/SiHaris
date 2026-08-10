part of 'reimbursement_summary_bloc.dart';

abstract class ReimbursementSummaryState extends Equatable {
  const ReimbursementSummaryState();

  @override
  List<Object?> get props => [];
}

class ReimbursementSummaryInitial extends ReimbursementSummaryState {}

class ReimbursementSummaryLoading extends ReimbursementSummaryState {}

class ReimbursementSummaryLoaded extends ReimbursementSummaryState {
  final ReimbursementSummaryModel summary;

  const ReimbursementSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class ReimbursementSummaryError extends ReimbursementSummaryState {
  final String message;

  const ReimbursementSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
