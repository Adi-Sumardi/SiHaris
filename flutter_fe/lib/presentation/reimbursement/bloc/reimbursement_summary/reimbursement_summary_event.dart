part of 'reimbursement_summary_bloc.dart';

abstract class ReimbursementSummaryEvent extends Equatable {
  const ReimbursementSummaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadReimbursementSummary extends ReimbursementSummaryEvent {
  final int month;
  final int year;

  const LoadReimbursementSummary({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}
