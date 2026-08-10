part of 'reimbursement_detail_bloc.dart';

abstract class ReimbursementDetailEvent extends Equatable {
  const ReimbursementDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadReimbursementDetail extends ReimbursementDetailEvent {
  final int id;

  const LoadReimbursementDetail(this.id);

  @override
  List<Object?> get props => [id];
}
