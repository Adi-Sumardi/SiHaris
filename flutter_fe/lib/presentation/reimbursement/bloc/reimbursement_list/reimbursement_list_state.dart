part of 'reimbursement_list_bloc.dart';

abstract class ReimbursementListState extends Equatable {
  const ReimbursementListState();

  @override
  List<Object?> get props => [];
}

class ReimbursementListInitial extends ReimbursementListState {}

class ReimbursementListLoading extends ReimbursementListState {}

class ReimbursementListLoaded extends ReimbursementListState {
  final List<ReimbursementModel> reimbursements;
  final bool hasReachedMax;

  const ReimbursementListLoaded(
    this.reimbursements, {
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [reimbursements, hasReachedMax];
}

class ReimbursementListError extends ReimbursementListState {
  final String message;

  const ReimbursementListError(this.message);

  @override
  List<Object?> get props => [message];
}
