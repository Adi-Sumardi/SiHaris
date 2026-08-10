part of 'reimbursement_list_bloc.dart';

abstract class ReimbursementListEvent extends Equatable {
  const ReimbursementListEvent();

  @override
  List<Object?> get props => [];
}

class LoadReimbursements extends ReimbursementListEvent {
  final String? status;
  final String? startDate;
  final String? endDate;
  final int page;

  const LoadReimbursements({
    this.status,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  @override
  List<Object?> get props => [status, startDate, endDate, page];
}

class RefreshReimbursements extends ReimbursementListEvent {
  final String? status;
  final String? startDate;
  final String? endDate;

  const RefreshReimbursements({this.status, this.startDate, this.endDate});

  @override
  List<Object?> get props => [status, startDate, endDate];
}
